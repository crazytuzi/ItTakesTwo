class UAttachToParentComponent : UActorComponent
{
	// The name of the component to attach to
	UPROPERTY(Category = "AttachToParentComponent", ShowOnActor)
	FName ComponentName;

	// The specific actor to attach to. If left blank, it uses the parent it's already attached to in the editor.
	UPROPERTY(Category = "AttachToParentComponent")
	AHazeActor AttachToActor;

	UPROPERTY(Category = "AttachToParentComponent")
	EAttachmentRule AttachmentRule = EAttachmentRule::KeepWorld;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AActor ParentActor;
		if (AttachToActor != nullptr)
			ParentActor = AttachToActor;
		else
			ParentActor = Owner.GetAttachParentActor();

		if (ParentActor != nullptr)
		{
			USceneComponent Target = USceneComponent::Get(ParentActor, ComponentName);
			if (Target != nullptr)
				Owner.AttachToComponent(Target, NAME_None, AttachmentRule);
		}
	}

}