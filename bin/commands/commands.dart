part of l10n.app;

class MsgMerge extends ShellCommand {
    MsgMerge() : super("msgmerge");
}

class MsgInit extends ShellCommand {
    MsgInit() : super("msginit");
}

class XGetText extends ShellCommand {
    XGetText() : super("xgettext");
}

final MsgMerge msgmerge = new MsgMerge();
final MsgInit msginit = new MsgInit();
final XGetText xgettext = new XGetText();


