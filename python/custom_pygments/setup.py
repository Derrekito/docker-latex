from setuptools import setup, find_packages

setup(
    name='custom-pygments-lexers',
    version='1.0',
    packages=find_packages(),
    py_modules=['pseudocode', 'rosepinemoon'],
    entry_points={
        'pygments.lexers': [
            'pseudocode = pseudocode:PseudocodeLexer',
            'pseudo = pseudocode:PseudocodeLexer',
            'algorithm = pseudocode:PseudocodeLexer',
        ],
        'pygments.styles': [
            'rosepinemoon = rosepinemoon:RosePineMoonStyle',
        ],
    },
)
