from splitwise.cli import build_parser, main


def test_parser_knows_its_name():
    assert build_parser().prog == "splitwise"


def test_main_with_no_arguments_prints_help_and_succeeds(capsys):
    assert main([]) == 0
    assert "usage: splitwise" in capsys.readouterr().out

