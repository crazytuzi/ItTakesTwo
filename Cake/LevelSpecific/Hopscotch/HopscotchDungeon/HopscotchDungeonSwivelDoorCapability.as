import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonSwiveldoor;
import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonSwiverDoorComponent;
import Vino.Tutorial.TutorialStatics;

class UHopscotchDungeonSwivelDoorCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HopscotchDungeonSwivelDoorCapability");

	default CapabilityDebugCategory = n"HopscotchDungeonSwivelDoorCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 90;

	AHazePlayerCharacter Player;
	UHopscotchDungeonSwivelDoorComponent DoorComp;

	bool bIsActive = false;

	UPROPERTY()
	UAnimSequence CodyEnterAnim;

	UPROPERTY()
	UAnimSequence CodyExitAnim;

	UPROPERTY()
	UAnimSequence CodyMhAnim;

	UPROPERTY()
	UAnimSequence MayEnterAnim;

	UPROPERTY()
	UAnimSequence MayExitAnim;

	UPROPERTY()
	UAnimSequence MayMhAnim;

	UAnimSequence EnterAnimToUse;
	UAnimSequence ExitAnimToUse;
	UAnimSequence MhAnimToUse;

	AHopscotchDungeonSwivelDoor SwivelDoor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DoorComp = UHopscotchDungeonSwivelDoorComponent::Get(Player);

		EnterAnimToUse = Game::GetCody() == Player ? CodyEnterAnim : MayEnterAnim;
		ExitAnimToUse = Game::GetCody() == Player ? CodyExitAnim : MayExitAnim;
		MhAnimToUse = Game::GetCody() == Player ? CodyMhAnim : MayMhAnim;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(DoorComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(DoorComp.SwivelDoor == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(DoorComp == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(DoorComp.SwivelDoor == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"SwivelDoor", DoorComp.SwivelDoor);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwivelDoor = Cast<AHopscotchDungeonSwivelDoor>(ActivationParams.GetObject(n"SwivelDoor"));

		bIsActive = true;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this, n"SwivelDoor");
		USceneComponent CompToAttachTo = Game::GetCody() == Player ? SwivelDoor.CodyPlacement : SwivelDoor.MayPlacement;
		Player.AttachToComponent(CompToAttachTo, n"", EAttachmentRule::SnapToTarget);
		ShowCancelPrompt(Player, this);

		FHazeAnimationDelegate AnimFinishedDelegate;
		AnimFinishedDelegate.BindUFunction(this, n"EnterFinished");
		Player.PlaySlotAnimation(OnBlendingOut = AnimFinishedDelegate, Animation = EnterAnimToUse, bLoop = false);

		FHazePointOfInterest Poi;
		Poi.FocusTarget.Component = Player == Game::GetCody() ? SwivelDoor.CodyPoiComp : SwivelDoor.MayPoiComp;
		Poi.Clamps.bUseClampYawLeft = true;
		Poi.Clamps.bUseClampYawRight = true;
		Poi.Clamps.bUseClampPitchDown = true;
		Poi.Clamps.bUseClampPitchUp = true;
		Poi.Clamps.ClampYawLeft = 20.f;
		Poi.Clamps.ClampYawRight = 20.f;
		Poi.Clamps.ClampPitchUp = 20.f;
		Poi.Clamps.ClampPitchDown = 20.f;
		Poi.Blend.BlendTime = 1.f;
		Player.ApplyClampedPointOfInterest(Poi, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bIsActive = false;
		Player.PlaySlotAnimation(Animation = ExitAnimToUse, bLoop = false, BlendTime = 0.2f);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		if (SwivelDoor != nullptr)
			SwivelDoor.PlayerStoppedUsingDoor(Player);

		//Player.StopAllSlotAnimations();
		RemoveCancelPromptByInstigator(Player, this);

		Player.ClearPointOfInterestByInstigator(this);

		SwivelDoor = nullptr;
	}

	UFUNCTION()
	void EnterFinished()
	{
		if (bIsActive)
			Player.PlaySlotAnimation(Animation = MhAnimToUse, bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!HasControl())
			return;
	
		if (IsActioning(n"DoneWithDoor"))
		{
			// Done in SwivelDoorAuroRunCapability instead!
			//AutoMoveCharacterForwards(Player, SwivelDoor.AutoMoveDuration, false);
			//SetNewSwivelDoor(Player, nullptr);
		}

		if(WasActionStarted(ActionNames::Cancel) && SwivelDoor.DoubleInteractComp.CanPlayerCancel(Player))
		{
			SwivelDoor.DoubleInteractComp.CancelInteracting(Player);
			SetNewSwivelDoor(Player, nullptr);
		}
	}
}