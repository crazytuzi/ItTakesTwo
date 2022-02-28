import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureZeroGravity;
import Cake.LevelSpecific.PlayRoom.SpaceStation.TractorBeamTerminal;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Vino.Movement.Jump.AirJumpsComponent;

class UTractorBeamMovementCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Gravity");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ATractorBeamTerminal TractorBeam;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureZeroGravity CodyZeroGFeature;
	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureZeroGravity MayZeroGFeature;

	UPROPERTY()
	USpacestationVOBank VOBank;

	FTimerHandle BarkHandle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"TractorBeam"))
        	return EHazeNetworkActivation::ActivateUsingCrumb;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"TractorBeam"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		TractorBeam = Cast<ATractorBeamTerminal>(GetAttributeObject(n"TargetTractorBeam"));
		OutParams.AddObject(n"TractorBeam", TractorBeam);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this);

		TractorBeam = Cast<ATractorBeamTerminal>(ActivationParams.GetObject(n"TractorBeam"));

		Player.PlayCameraShake(TractorBeam.CaughtAndReleasedCameraShake);
		Player.PlayForceFeedback(TractorBeam.CaughtAndReleasedForceFeedback, false, true, n"TractorBeam");

		Player == Game::GetCody() ? Player.AddLocomotionFeature(CodyZeroGFeature) : Player.AddLocomotionFeature(MayZeroGFeature);

		Player.BlockCapabilities(CapabilityTags::Movement, this);

		Player.AttachToComponent(TractorBeam.TractorBeamEffect, AttachmentRule = EAttachmentRule::KeepWorld);

		FVector Loc = FMath::ClosestPointOnLine(TractorBeam.TractorBeamEffect.WorldLocation, TractorBeam.TractorBeamEffect.WorldLocation + (TractorBeam.TractorBeamEffect.UpVector * 10000.f), Player.ActorLocation);
		Player.SmoothSetLocationAndRotation(Loc, Player.ActorRotation, 200.f);

		UCharacterAirJumpsComponent AirJumpsComp = UCharacterAirJumpsComponent::Get(Player);
		if (AirJumpsComp != nullptr)
			AirJumpsComp.ConsumeJumpAndDash();

		if (Player.IsCody())
		{
			ForceCodyMediumSize();
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationTractorBeamReactionCody");
			BarkHandle = System::SetTimer(this, n"PlayLongTimeBark", 10.f, false);
		}
		else if (Player.IsMay())
		{
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationTractorBeamReactionMay");
			Player.SetCapabilityActionState(n"GravityPathAlignmentBlocked", EHazeActionState::Active);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.TriggerMovementTransition(this);
		Player == Game::GetCody() ? Player.RemoveLocomotionFeature(CodyZeroGFeature) : Player.RemoveLocomotionFeature(MayZeroGFeature);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		Player.PlayCameraShake(TractorBeam.CaughtAndReleasedCameraShake);
		Player.PlayForceFeedback(TractorBeam.CaughtAndReleasedForceFeedback, false, true, n"TractorBeam");

		if (Player.IsMay())
			Player.SetCapabilityActionState(n"GravityPathAlignmentBlocked", EHazeActionState::Inactive);
		else
			System::ClearAndInvalidateTimerHandle(BarkHandle);
	}

	UFUNCTION()
	void PlayLongTimeBark()
	{
		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationTractorBeamHint");
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (Player.IsMay())
			Player.SetCapabilityActionState(n"GravityPathAlignmentBlocked", EHazeActionState::Inactive);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData Data;
		Data.AnimationTag = n"ZeroGravity";
		Player.RequestLocomotion(Data);
	}
}
