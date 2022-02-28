import Cake.LevelSpecific.Clockwork.Townsfolk.StaticTownsFolkActor;

class ATownsfolkDiner : AStaticTownsFolkActor
{
	UPROPERTY()
	AActor RightAttachedThing;

	UPROPERTY()
	FTransform RightAttachmentOffset = FTransform::Identity;

	UPROPERTY()
	AActor LeftAttachedThing;

	UPROPERTY()
	FTransform LeftAttachmentOffset = FTransform::Identity;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript() override
	{
		Super::ConstructionScript();

		if (RightAttachedThing != nullptr)
		{
			RightAttachedThing.AttachToComponent(SkelMeshComp, n"RightAttach");
			RightAttachedThing.SetActorRelativeTransform(RightAttachmentOffset);
		}

		if (LeftAttachedThing != nullptr)
		{
			LeftAttachedThing.AttachToComponent(SkelMeshComp, n"LeftAttach");
			LeftAttachedThing.SetActorRelativeTransform(LeftAttachmentOffset);
		}
	}
}