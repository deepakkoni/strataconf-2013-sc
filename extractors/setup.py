from distutils.core import setup

# import os.path
# import glob

setup(
    name='criminality',
    version='0.1.1a2',
    author='Jeremy G. Kahn',
    author_email='jkahn@inome.com',
    packages=['criminality',
              ],
    # package_data={'criminality':['data/*.json']},
    # scripts=glob.glob(os.path.join('tools', 'gemini-*')),
    # http://gitlab.datarepo1.tuk2.intelius.com/criminality',
    # license=open('LICENSE.txt').read(),
    description='library of feature-extractors from minor crim offenses',
    long_description=open('README.md').read(),
    install_requires=[ "Gemini>=0.2.3a1",
                       ]
    )

