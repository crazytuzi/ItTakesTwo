import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Shed.Vacuum.GoingThroughVacuumCapability;
import Vino.Movement.Capabilities.Skydive.SkydiveStatics;
import Vino.Movement.Jump.AirJumpsComponent;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureZeroGravity;
import Cake.LevelSpecific.Shed.Vacuum.LaunchedFromVacuumCapability;
import Cake.LevelSpecific.Shed.VOBanks.VacuumVOBank;

class UVacuumLaunchIntoSkydiveCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"GameplayAction");
    default CapabilityTags.Add(n"Vacuum");
	default CapabilityTags.Add(n"LevelSpecific");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 5;

	AHazePlayerCharacter Player;

	bool bLaunching = false;

	AActor LaunchTarget;

	AVacuumHoseActor Hose;
	EVacuumMountLocation MountLocation;

	float InitialDistanceToTarget = 0.f;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureZeroGravity CodyZeroGFeature;
	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureZeroGravity MayZeroGFeature;

	UPROPERTY()
	UForceFeedbackEffect LaunchForceFeedback;

	FTimerHandle BarkHandle;

	UPROPERTY()
	UVacuumVOBank VOBank;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"LaunchIntoSkydive"))
            return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bLaunching)
			return EHazeNetworkDeactivation::DontDeactivate;
        
		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Hose = Cast<AVacuumHoseActor>(GetAttributeObject(n"Hose"));
		MountLocation = GetAttributeNumber(n"MountLocation") == 0 ? EVacuumMountLocation::Front : EVacuumMountLocation::Back;
		Hose.RemoveBulgingActor(Player);

		Player.ClearPointOfInterestByInstigator(Hose);

		bLaunching = true;

		Player.PlayForceFeedback(LaunchForceFeedback, false, false, n"Launch");

        Player.SetCapabilityActionState(n"LaunchIntoSkydive", EHazeActionState::Inactive);
		LaunchTarget = Cast<AActor>(GetAttributeObject(n"LaunchTarget"));

		InitialDistanceToTarget = GetDistanceToTarget();

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		Player.SetAnimBoolParam(n"LaunchIntoSkydive", true);
		Player.SetAnimFloatParam(n"StopSpinningTime", Hose.StopSpinningTime);
		Player.SetAnimFloatParam(n"ForwardRotationSpeed", Hose.ForwardRotationSpeed);
		Player.SetAnimFloatParam(n"SideRotationSpeed", Hose.SideRotationSpeed);
		Player.SetAnimBoolParam(n"SkipStart", Hose.bSkipStart);
		Player == Game::GetCody() ? Player.AddLocomotionFeature(CodyZeroGFeature) : Player.AddLocomotionFeature(MayZeroGFeature);

		if (Hose.bPlayLaunchBarks)
			BarkHandle = System::SetTimer(this, n"PlayBark", 0.5f, true);
	}

	UFUNCTION()
	void PlayBark()
	{
		if (Player.IsMay())
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumLaunchedFromHoseEffortMay");
		else
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumLaunchedFromHoseEffortCody");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.UnblockCapabilities(CapabilityTags::Collision, Hose);

		MoveComp.StopMovement();

		ActivateSkydive(Player);
		
		UCharacterAirJumpsComponent AirJumpsComp = UCharacterAirJumpsComponent::Get(Player);
		if (AirJumpsComp != nullptr)
			AirJumpsComp.ConsumeJumpAndDash();

		Player == Game::GetCody() ? Player.RemoveLocomotionFeature(CodyZeroGFeature) : Player.RemoveLocomotionFeature(MayZeroGFeature);

		System::ClearAndInvalidateTimerHandle(BarkHandle);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bLaunching)
			return;

		if (!MoveComp.CanCalculateMovement())
			return;

		if (Player.HasControl())
		{
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"ZeroGravity");
			FVector DirToTarget = LaunchTarget.ActorLocation - Player.ActorLocation;
			DirToTarget.Normalize();

			float DistanceAlpha = GetDistanceToTarget()/InitialDistanceToTarget;
			float MoveSpeed = FMath::Lerp(900.f, 5000.f, DistanceAlpha);

			FVector DeltaMove = DirToTarget * MoveSpeed * DeltaTime;
			MoveData.ApplyDelta(DeltaMove);

			Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceX, 0.f);
			Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceY, -1000.f);
			
			MoveCharacter(MoveData, n"ZeroGravity");
			CrumbComp.LeaveMovementCrumb();

			if (Player.ActorLocation.Equals(LaunchTarget.ActorLocation, 50.f))
				bLaunching = false;
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"AirMovement");
			MoveData.ApplyDelta(ConsumedParams.DeltaTranslation);

			MoveData.ApplyTargetRotationDelta();

			MoveCharacter(MoveData, n"ZeroGravity");
		}
	}

	float GetDistanceToTarget()
	{
		return (LaunchTarget.ActorLocation - Player.ActorLocation).Size();
	}
}