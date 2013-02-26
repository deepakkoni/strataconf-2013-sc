set ?= strata-2013-sc
state ?= DE
featureset ?= feats02
modelset ?= model03

jboost-dir := /atlas/spock/jkahn/jboost/jboost-2.1

default: 
	@echo "example use"
	@echo "  make -f train.mk get_labeled"
	@echo "  make -f train.mk --jobs 4 train"

##########
PROJ=train
define virtual_environment_requirement_list
Gemini>=0.2.7a5
endef

virtual-environment-name := $(PROJ)-venv
virtual-environment-requirements := $(PROJ)-requirements.txt

include venv.mk

bindir := $(virtual-environment-bin)

workdir := $(PROJ)-$(set)-$(state)-workdir
model := model/$(featureset)-$(modelset).yaml

labeled-data := ../data/$(state)/learner-data

features_dir := $(workdir)/features-$(featureset)
exemplar_dir := $(labeled-data)/dataset
label_dir := $(labeled-data)/labels

labels=$(wildcard $(label_dir)/labels-*.avro)
exemplars=$(wildcard $(exemplar_dir)/dataset-*.avro)

feature_config := feature_config/$(featureset).yaml
train_config := model_config/$(modelset).yaml

features := $(patsubst $(exemplar_dir)/dataset-%.avro,$(features_dir)/features-%.avro,$(exemplars))

.PRECIOUS: $(features)

info:
	@echo "exemplar dir: $(exemplar_dir)"
	@echo "features: $(features)"

$(features_dir)/features-%.avro: $(exemplar_dir)/dataset-%.avro $(feature_config) $(virtual-environment-install-file)
	$(bindir)/gemini-extract-features \
	   --legacy-records \
	   --config $(feature_config) \
	   --write $@  --write-format avro \
	   --read-format slowavro $<

.PHONY: extract
feature-file := $(workdir)/features.done
extract: $(feature-file)
$(feature-file): $(features_dir) $(features) $(feature_config)
	echo -n '# done ' > $@
	date >> $@
	cat $(feature_config) >> $@

.PHONY: train
train: $(model)

$(model): $(feature-file) $(labels) $(train_config) $(virtual-environment-install-file)
	mkdir -p `dirname $@`
	$(bindir)/gemini-train-model --fvectors $(features) --labels $(labels) \
	  --config $(train_config) --model $@ --scratch $(workdir)/train-scratch

$(workdir) $(features_dir):
	mkdir -p $@

visualize-model: $(model)
	$(jboost-dir)/scripts/atree2dot2ps.pl \
	   -i $(workdir)/train-scratch/jboost-model.info \
	   -t $(workdir)/train-scratch/jboost-model.tree
	ps2pdf $(workdir)/train-scratch/jboost-model.tree.0.ps
	mv jboost-model.tree.0.pdf $(workdir)/$(state)-$(featureset)-$(modelset)-tree.pdf
