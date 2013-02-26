xval-info:
	@echo "> make -f xval.mk unzip-xvals"
	@echo AND THEN:
	@echo "> make -f xval.mk xval-pr-report"

include train.mk
FOLDS ?= 10

XVALDIR ?= $(workdir)/xval-$(FOLDS)fold-$(featureset)-$(modelset)
fold-dirs := $(shell seq -f "$(XVALDIR)/fold-%02g" 1 $(FOLDS))
fold-dirs-installed := $(foreach fold,$(fold-dirs),$(fold)/.fold-dir-installed)

$(fold-dirs-installed):
	mkdir -p `dirname $@`
	date > $@
xval-dirs: $(fold-dirs-installed)
.PHONY: xval-dirs

#################################
xfold-feature-files := $(foreach fold,$(fold-dirs),$(fold)/features.avro) 
xfold-unzipped-features = $(XVALDIR)/.features-installed
$(xfold-unzipped-features): $(fold-dirs-installed) $(feature-file)
	$(bindir)/gasket-unzip --write $(xfold-feature-files) \
	  --read-format slowavro --write-format avro \
	  -- $(features)
	date > $@
#################################
xfold-label-files := $(foreach fold,$(fold-dirs),$(fold)/labels.avro) 
xfold-unzipped-labels = $(XVALDIR)/.labels-installed
$(xfold-unzipped-labels): $(fold-dirs-installed) $(labels)
	$(bindir)/gasket-unzip --write $(xfold-label-files) \
	  --read-format slowavro --write-format avro \
	  -- $(labels)
	date > $@
#################################
unzip-xvals: $(xfold-unzipped-features) $(xfold-unzipped-labels)
	@echo "done writing folds 1-$(FOLDS) to $(XVALDIR)"
.PHONY: unzip-xvals

#################################

cross-models-trained = $(XVALDIR)/.xfold-models-trained
cross-models := $(foreach fold,$(fold-dirs),$(fold)/model.yaml)

ifndef THIS_FOLD
# kickoff at root -- no fold specified
$(cross-models): $(XVALDIR)/%/model.yaml: $(xfold-unzipped-features) $(xfold-unzipped-labels)
	$(MAKE) -f xval.mk THIS_FOLD=$* $@
else
# THIS_FOLD defined -- list the complementary folds
other-features = $(filter-out $(XVALDIR)/$(THIS_FOLD)/features.avro,$(xfold-feature-files))
other-labels = $(filter-out $(XVALDIR)/$(THIS_FOLD)/labels.avro,$(xfold-label-files))
$(XVALDIR)/$(THIS_FOLD)/model.yaml: $(other-features) $(other-labels) $(train_config)
	$(bindir)/gemini-train-model \
	  --fvectors $(other-features) \
	  --labels $(other-labels) \
	  --config $(train_config) --model $@ \
	  --scratch $(XVALDIR)/$(THIS_FOLD)/train-scratch
endif
$(cross-models-trained): $(cross-models)
	date > $@
crosstrain: $(cross-models-trained)
.PHONY: crosstrain

#################################

cross-evals-done = $(XVALDIR)/.xfold-evals-run
cross-evals := $(foreach fold,$(fold-dirs),$(fold)/scores.avro)
$(cross-evals): $(XVALDIR)/%/scores.avro: $(XVALDIR)/%/model.yaml $(XVALDIR)/%/features.avro
	$(bindir)/gemini-apply-model \
	  --model $(XVALDIR)/$*/model.yaml \
	  --write-format avro --write $@ \
	  --read-format avro $(XVALDIR)/$*/features.avro
$(cross-evals-done): $(cross-evals)
	date > $@
crossapply: $(cross-evals-done)
.PHONY: crossapply

#################################

macro-file := $(XVALDIR)/xval-macro.avro

$(macro-file): $(cross-evals) $(xfold-label-files)
	$(bindir)/gasket-kvjoin --read-format slowavro \
	  --field score --data $(cross-evals) \
	  --field judgment --data $(xfold-label-files) \
	  --write $@ --write-format avro

macro-file-sorted := $(XVALDIR)/xval-macro-sorted.avro

$(macro-file-sorted): $(macro-file)
	$(bindir)/gasket-sort --read-format slowavro \
	  --key-path val.score.label --reverse \
	  --write $@ --write-format avro \
	  $<

#################################

pr-report := $(XVALDIR)/xval-pr-report.txt

PRECISION_POINTS=[0.5,0.6,0.7,0.8,0.9,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,1.0]

$(pr-report): $(macro-file-sorted)
	$(bindir)/gemini-precision-recall \
	  --score-path='val.score.label' \
	  --label-path='val.judgment.label' \
	  --precision-points "$(PRECISION_POINTS)" \
	  --read $< > $@

xval-pr-report: $(pr-report)
.PHONY: xval-pr-report
