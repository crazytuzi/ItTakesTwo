class USplineBoatPlayerAttachComponent : UActorComponent
{
	void ChangeAttach(AHazeActor TargetActor, bool bIsAttaching)
	{
		if (bIsAttaching)
			Owner.AttachToActor(TargetActor, NAME_None, EAttachmentRule::KeepWorld);
		else
			Owner.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}
}