import Vino.Interactions.InteractionComponent;
import Vino.Interactions.OneShotInteraction;

UCLASS(Abstract)
class APushableShovel : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShovelBase;

	UPROPERTY(DefaultComponent, Attach = ShovelBase)
	UStaticMeshComponent ShovelMesh;

	UPROPERTY(DefaultComponent, Attach = ShovelBase)
	UInteractionComponent JumpOnComp;
	default JumpOnComp.bStartDisabled = true;
	default JumpOnComp.StartDisabledReason = n"Still";

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyPerchAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayPerchAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyLaunchAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayLaunchAnim;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveShovelTimeLike;

	UPROPERTY()
	AOneShotInteraction PushInteraction;

	float StartRot = 0.f;

	AHazePlayerCharacter PerchedPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveShovelTimeLike.BindUpdate(this, n"UpdateMoveShovel");
		MoveShovelTimeLike.BindFinished(this, n"FinishMoveShovel");

		StartRot = ShovelBase.RelativeRotation.Pitch;

		if (PushInteraction != nullptr)
			PushInteraction.OnOneShotActivated.AddUFunction(this, n"OnPushActivated");
		else
			Print("SHOVEL HAS NO VALID INTERACTION ASSIGNED", 20.f);

		JumpOnComp.OnActivated.AddUFunction(this, n"OnJumpOnActivated");
	}

	UFUNCTION()
    void OnPushActivated(AHazePlayerCharacter Player, AOneShotInteraction Interaction)
    {
		Interaction.DisableInteraction(n"Pushed");
		MoveShovelTimeLike.PlayFromStart();
    }

	UFUNCTION()
    void OnJumpOnActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		PerchedPlayer = Player;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.AttachToComponent(ShovelBase, AttachmentRule = EAttachmentRule::KeepWorld);

		UAnimSequence Anim = Player.IsCody() ? CodyPerchAnim : MayPerchAnim;
		Player.PlaySlotAnimation(Animation = Anim, bLoop = true);
    }

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveShovel(float CurValue)
	{
		float CurPitch = FMath::Lerp(StartRot, 0.f, CurValue);
		ShovelBase.SetRelativeRotation(FRotator(CurPitch, 0.f, 0.f));

		if (CurValue > 0.65f && PerchedPlayer == nullptr)
		{
			Print("NOOOOOW");
			JumpOnComp.Enable(n"Still");
		}
		else
		{
			JumpOnComp.Disable(n"Still");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveShovel()
	{
		PushInteraction.EnableInteraction(n"Pushed");

		if (PerchedPlayer != nullptr)
		{
			PerchedPlayer.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			PerchedPlayer.UnblockCapabilities(CapabilityTags::Movement, this);

			FVector LaunchForce = (PerchedPlayer.ActualVelocity/3) + FVector(0.f, 0.f, 2500.f);
			PerchedPlayer.AddImpulse(LaunchForce);

			UAnimSequence Anim = PerchedPlayer.IsCody() ? CodyLaunchAnim : MayLaunchAnim;
			PerchedPlayer.PlaySlotAnimation(Animation = Anim);

			PerchedPlayer = nullptr;
		}
	}
}