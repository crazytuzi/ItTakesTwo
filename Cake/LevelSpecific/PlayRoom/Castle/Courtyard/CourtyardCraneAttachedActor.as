class ACourtyardCraneAttachedActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereTrigger;
	default SphereTrigger.CollisionEnabled = ECollisionEnabled::QueryOnly;
	default SphereTrigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SphereTrigger.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Overlap);
	default SphereTrigger.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;

	AHazeActor CraneActorRef;
	FVector AngularVelocity = FVector(0.f, 0.f, 0.f);
	FVector LinearVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"CourtyardCraneRadialTranslationCapability");
	}

	void AttachToCrane(AHazeActor CraneActor, USceneComponent ConstraintPoint)
	{
		CraneActorRef = CraneActor;
		SetCapabilityActionState(n"Attached", EHazeActionState::Active);
	}
}