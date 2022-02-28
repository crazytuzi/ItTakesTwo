import Cake.LevelSpecific.Shed.Vacuum.PushablePiston;
import Vino.Tutorial.TutorialStatics;

UCLASS(Abstract)
class UPushPistonCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GameplayAction");
	default CapabilityTags.Add(n"LevelSpecific");

	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;

    UHazeBaseMovementComponent Movement;

    APushablePiston Piston;

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyEnterAnimation;

	UPROPERTY(Category = "Animation")
	UAnimSequence MayEnterAnimation;

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyExitAnimation;

	UPROPERTY(Category = "Animation")
	UAnimSequence MayExitAnimation;

	UPROPERTY(Category = "Animation")
	UBlendSpace1D CodyBS;

	UPROPERTY(Category = "Animation")
	UBlendSpace1D MayBS;	

	FVector2D Input;

	bool bFullyEntered = false;

	bool bClampHit = false;

	FVector LastOffset;

	bool bBarkPlayed = false;

	bool bSlamShut = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
        Movement = UHazeBaseMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!IsActioning(n"PushingPiston"))
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (!bFullyEntered)
            return EHazeNetworkDeactivation::DontDeactivate;

		if (!WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DontDeactivate;
        
		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
        OutParams.AddObject(n"Piston", GetAttributeObject(n"Piston"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LastOffset = FVector::ZeroVector;
		bFullyEntered = false;

        Piston = Cast<APushablePiston>(ActivationParams.GetObject(n"Piston"));

        ConsumeAttribute(n"Piston", Piston);

		Player.TriggerMovementTransition(this);
        Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

        UAnimSequence PushEnter = Player.IsCody() ? CodyEnterAnimation : MayEnterAnimation;

		FHazeAnimationDelegate OnEnterFinished;
		OnEnterFinished.BindUFunction(this, n"EnterAnimFinished");

        Player.PlaySlotAnimation(OnBlendingOut = OnEnterFinished, Animation = PushEnter, BlendTime = 0.1f, bLoop = false);

		UBlendSpace1D BS = Player.IsMay() ? MayBS : CodyBS;
		Player.PlayBlendSpace(BS);

		Player.AttachToComponent(Piston.Base, AttachmentRule = EAttachmentRule::KeepWorld);

		Player.ApplyCameraSettings(Piston.CamSettings, FHazeCameraBlendSettings(1.f), this);
	}

	UFUNCTION()
	void EnterAnimFinished()
	{
		bFullyEntered = true;
		ShowCancelPrompt(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		if (Piston.Base.RelativeLocation != FVector::ZeroVector)
			OutParams.AddActionState(n"SlamShut");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bSlamShut = DeactivationParams.GetActionState(n"SlamShut");
		System::SetTimer(this, n"ReleasePiston", 0.08f, false);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementGroundPound);

        Player.SetCapabilityActionState(n"PushingPiston", EHazeActionState::Inactive);
        Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		UAnimSequence ExitAnim = Player.IsCody() ? CodyExitAnimation : MayExitAnimation;

		FHazeAnimationDelegate OnExitAnimFinished;
		OnExitAnimFinished.BindUFunction(this, n"ExitAnimationFinished");

		Player.StopBlendSpace();

		Player.PlaySlotAnimation(OnBlendingOut = OnExitAnimFinished, Animation = ExitAnim, BlendTime = 0.06f, bLoop = false);

		RemoveCancelPromptByInstigator(Player, this);

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void ReleasePiston()
	{
		if (Piston != nullptr)
			Piston.ReleasePiston(bSlamShut);
	}

	UFUNCTION()
	void ExitAnimationFinished()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (bFullyEntered)
		{
			Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			if (Input.Y > 0.1f)
				Input.Y = 1.f;
			else if (Input.Y < -0.1f)
				Input.Y = -1.f;
			Piston.MovePiston(Input);

			float BlendSpaceValue = Input.Y;

			float CurrentPistonOffset =  Piston.Base.RelativeLocation.X;
			if (CurrentPistonOffset == Piston.MaxOffset)
				BlendSpaceValue = 0.f;
			else if (CurrentPistonOffset == 0.f)
				BlendSpaceValue = 0.f;


			if (LastOffset.Equals(Piston.SyncVectorComp.Value, 0.1f))
				BlendSpaceValue = 0.f;
			else if (LastOffset.X > Piston.SyncVectorComp.Value.X)
				BlendSpaceValue = -1.f;
			else if (LastOffset.X < Piston.SyncVectorComp.Value.X)
				BlendSpaceValue = 1.f;

			LastOffset = Piston.SyncVectorComp.Value;

			Piston.HazeAkCompPiston.SetRTPCValue("Rtpc_Platform_Shed_Vacuum_PushablePiston_Velocity", BlendSpaceValue);

			Player.SetBlendSpaceValues(BlendSpaceValue);

			if (Piston.bClampHitLastFrame)
			{
				if (!bClampHit)
				{
					bClampHit = true;
					Player.PlayForceFeedback(Piston.HitClampForceFeedback, false, true, n"PistonClamp");
				}
			}
			else
			{
				bClampHit = false;
			}

			float DistToOtherPlayer = Piston.BarkDistanceCheckOrigin.WorldLocation.Distance(Player.OtherPlayer.ActorLocation);
			if (Piston.Base.RelativeLocation.X < -50.f && !bBarkPlayed && Piston.bPlayBarks && DistToOtherPlayer <= 1000.f)
			{
				bBarkPlayed = true;
				if (Player.IsCody())
				{
					Piston.VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumChipRoomEntranceMayEntersCody");
					System::SetTimer(this, n"PlayOtherPlayerBark", 1.5f, false);
				}
				else
				{
					Piston.VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumChipRoomEntranceCodyEntersMay");
					System::SetTimer(this, n"PlayOtherPlayerBark", 1.5f, false);
				}
			}
		}
	}

	UFUNCTION()
	void PlayOtherPlayerBark()
	{
		if (Piston == nullptr)
			return;

		if (!IsActive())
			return;

		float DistToOtherPlayer = Piston.BarkDistanceCheckOrigin.WorldLocation.Distance(Player.OtherPlayer.ActorLocation);
		if (DistToOtherPlayer <= 1000.f)
		{
			if (Player.IsCody())
				Piston.VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumChipRoomEntranceMayEntersMay");
			else
				Piston.VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumChipRoomEntranceCodyEntersCody");
		}
	}
}