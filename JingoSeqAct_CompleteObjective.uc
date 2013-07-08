class JingoSeqAct_CompleteObjective extends SequenceAction;

event Activated()
{
	local array<Object> Linked;
	
	GetObjectVars(Linked);
	JingoItem_Objective(Linked[0]).CompleteObjective();
	ActivateOutputLink(0);
}

defaultproperties
{
	ObjName="Complete Jingo Objective"
	ObjCategory="Jingo"
	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="Objective", PropertyName=Objective)
}