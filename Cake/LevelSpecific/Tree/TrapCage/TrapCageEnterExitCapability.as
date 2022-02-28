
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.TrapCage.TrapCagePlayerComponent;

class UTrapCageEnterExitCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::AirMovement);
	default CapabilityTags.Add(MovementSystemTags::Falling);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	default CapabilityDebugCategory = n"TrapCage";

	const float MoveSpeed = 2000.f;

	AHazePlayerCharacter Player;
	UTrapCagePlayerComponent TrapComponent;
	UHazeSplineFollowComponent SplineFollow;
	EHazeUpdateSplineStatusType CurrentSplineStatus;

	float CurrentLerpTowardSplineSpeed;
	bool bIsFollowingSpline;
	FVector TaretSplineEnterPosition;
	float MoveToSplineMultiplier;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(CharacterOwner);
		TrapComponent = UTrapCagePlayerComponent::Get(Player);
		SplineFollow = UHazeSplineFollowComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(TrapComponent.EnterExitState == ETrapCageState::Entering)
			return EHazeNetworkActivation::ActivateLocal;

		if(TrapComponent.EnterExitState == ETrapCageState::Exiting)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(CurrentSplineStatus == EHazeUpdateSplineStatusType::AtEnd 
			|| CurrentSplineStatus == EHazeUpdateSplineStatusType::Invalid)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(CapabilityTags::Movement, true);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);

		Player.TriggerMovementTransition(this);
		Player.BlockMovementSyncronization(this);

		if(TrapComponent.EnterExitState == ETrapCageState::Entering)
		{
			MoveToSplineMultiplier = 150.f;
			CurrentLerpTowardSplineSpeed = 0;
			TaretSplineEnterPosition = TrapComponent.EnterExitSpline.GetLocationAtDistanceAlongSpline(
				0, ESplineCoordinateSpace::World);
		}
		else
		{
			MoveToSplineMultiplier = 800.f;
			CurrentLerpTowardSplineSpeed = 100;
			TaretSplineEnterPosition = TrapComponent.EnterExitSpline.GetLocationAtDistanceAlongSpline(
				TrapComponent.EnterExitSpline.GetSplineLength(), ESplineCoordinateSpace::World);
		}

		CurrentSplineStatus = EHazeUpdateSplineStatusType::Valid;
		Player.AddLocomotionFeature(TrapComponent.FreeFlyAsset);

		if(TrapComponent.EnterExitState == ETrapCageState::Entering)
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Player_IsInsideGlass", 1.f, 300.f);
		else if(TrapComponent.EnterExitState == ETrapCageState::Exiting)
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Player_IsInsideGlass", 0.f, 300.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(CapabilityTags::Movement, false);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);

		Player.UnblockMovementSyncronization(this);
		Player.RemoveLocomotionFeature(TrapComponent.FreeFlyAsset);
		SplineFollow.DeactivateSplineMovement();

		if(TrapComponent.EnterExitState == ETrapCageState::Entering)
		{
			TrapComponent.SetInsideState();
			MoveComp.AddImpulse(-FVector::UpVector * 1500.f);
		}
		else
		{
			TrapComponent.SetOutsideState();
			MoveComp.AddImpulse(-FVector::UpVector * 2500.f);
		}

		bIsFollowingSpline = false;
		CurrentLerpTowardSplineSpeed = 0;
		CurrentSplineStatus = EHazeUpdateSplineStatusType::Invalid;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"SuckMovement");

		if(bIsFollowingSpline)
		{
			FHazeSplineSystemPosition SplinePosition;
			CurrentLerpTowardSplineSpeed = FMath::FInterpTo(CurrentLerpTowardSplineSpeed, MoveSpeed, DeltaTime, 10.f);
			CurrentSplineStatus = SplineFollow.UpdateSplineMovement(CurrentLerpTowardSplineSpeed * DeltaTime, SplinePosition);
			MoveComp.SetTargetFacingRotation(SplinePosition.GetWorldRotation());
			FinalMovement.ApplyDelta(SplinePosition.GetWorldLocation() - Player.GetActorLocation());
			FinalMovement.ApplyTargetRotationDelta();
		}
		else
		{
			const FVector NewPlayerPosition = FMath::VInterpConstantTo(Player.GetActorLocation(), TaretSplineEnterPosition, DeltaTime, CurrentLerpTowardSplineSpeed);
			FVector DeltaMove = NewPlayerPosition - Player.GetActorLocation();
			FinalMovement.ApplyDelta(DeltaMove);
			CurrentLerpTowardSplineSpeed += (DeltaTime * MoveToSplineMultiplier) + (CurrentLerpTowardSplineSpeed * DeltaTime);
			if(TaretSplineEnterPosition.DistSquared(NewPlayerPosition) < FMath::Square(5.f))
			{
				bIsFollowingSpline = true;
				CurrentLerpTowardSplineSpeed = FMath::Min(CurrentLerpTowardSplineSpeed, MoveSpeed);
				const bool bMoveForward = TrapComponent.EnterExitState == ETrapCageState::Entering;
				SplineFollow.ActivateSplineMovement(TrapComponent.EnterExitSpline, bMoveForward);
			}
		}

		MoveCharacter(FinalMovement, n"ZeroGravity");
	}
}