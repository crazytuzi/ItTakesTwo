import Cake.LevelSpecific.Hopscotch.HopscotchSlinkyTunnel;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

enum ESlinkyMovementState
{
	Setup,
	MovingToStart,
	MovingThroughTunnel,
	Finished
}

class UHopscotchSlinkyTunnelCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"HopscotchSlinkyTunnelCapability");

	default CapabilityDebugCategory = n"HopscotchSlinkyTunnelCapability";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	AHopscotchSlinkyTunnel SlinkyTunnel;

	ESlinkyMovementState SlinkyMovementState;
	FVector PlayerStartLocation = FVector::ZeroVector;
	float StartMovementLerp = 0.f;
	float StartMovementDuration = 1.f;
	float ExtendTunnelTimer = 0.f;

	float MoveThroughTunnelDistance = 0.f;
	float MoveThroughTunnelSpeed = 5000.f;

	UPROPERTY()
	UHazeLocomotionFeatureBase CodyFeature;

	UPROPERTY()
	UHazeLocomotionFeatureBase MayFeature;

	UHazeLocomotionFeatureBase FeatureToUse; 


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Super::Setup(SetupParams);

		FeatureToUse = Player == Game::GetCody() ? CodyFeature : MayFeature;
		Player.AddLocomotionFeature(FeatureToUse);
		SlinkyMovementState = ESlinkyMovementState::Setup;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.RemoveLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GetAttributeObject(n"SlinkyTunnel") == nullptr)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SlinkyMovementState == ESlinkyMovementState::Finished)
		    return EHazeNetworkDeactivation::DeactivateLocal;
        else
            return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this);
		SlinkyTunnel = Cast<AHopscotchSlinkyTunnel>(GetAttributeObject(n"SlinkyTunnel"));
		PlayerStartLocation = Player.GetActorLocation();
		StartMovementLerp = 0.f;
		StartMovementDuration = 1.f;
		ExtendTunnelTimer = 0.f;
		MoveThroughTunnelDistance = 0.f;
		MoveThroughTunnelSpeed = 5000.f;
		
		
		SlinkyMovementState = ESlinkyMovementState::MovingToStart;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		SetStartMovementPointOfInterest();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearCameraOffsetOwnerSpaceByInstigator(this);
		Player.ClearPivotOffsetByInstigator(this);
		SlinkyTunnel.PlayerExitedSlinky(Player);
		Player.SetCapabilityAttributeObject(n"SlinkyTunnel", nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement SlinkyMove;

		switch (SlinkyMovementState)
		{
			case ESlinkyMovementState::MovingToStart:
				ExtendTunnelTimer -= DeltaTime;
				if (ExtendTunnelTimer <= 0.f)
					SlinkyTunnel.ExtendTunnel();

				SlinkyMove = CalculateToStartMovement(DeltaTime);
				break;

			case ESlinkyMovementState::MovingThroughTunnel:
				SetCameraPointOfInterest();
				SlinkyMove = CalculateThroughTunnelMovement(DeltaTime);
				break;

			case ESlinkyMovementState::Finished:
				break;
		}	

		if (!SlinkyMove.ContainsNaN() && MoveComp.CanCalculateMovement())
			MoveCharacter(SlinkyMove, n"HopscotchSlinky");
	}

	FHazeFrameMovement CalculateToStartMovement(float DeltaTime)
	{
		FHazeFrameMovement ToStartFrameMove = MoveComp.MakeFrameMovement(n"SlinkyToStartMove");
		StartMovementLerp += DeltaTime / StartMovementDuration;
		FVector TargetPos = SlinkyTunnel.GetActorLocation();
		
		if (Player == Game::GetCody())
			TargetPos += FVector(0.f, 0.f, 100.f);
		else
			TargetPos += FVector(0.f, 0.f, -100.f);
		
		FVector NewPos = FMath::EaseInOut(PlayerStartLocation, TargetPos, FMath::Min(StartMovementLerp, 1.f), .5f);
		
		ChangeFieldOfView(StartMovementLerp);
		
		FVector Delta = NewPos - Player.GetActorLocation();
		
		if (!ToStartFrameMove.ContainsNaN())
			ToStartFrameMove.ApplyDelta(Delta);

		if (StartMovementLerp >= 1.f)
		{
			SlinkyMovementState = ESlinkyMovementState::MovingThroughTunnel;
			Player.ClearFieldOfViewByInstigator(this, .5f);
			SlinkyTunnel.PlayerEnteredSlinky(Player);
		}	

		return ToStartFrameMove;
	}

	FHazeFrameMovement CalculateThroughTunnelMovement(float DeltaTime)
	{
		FHazeFrameMovement ThroughTunnelFrameMove = MoveComp.MakeFrameMovement(n"SlinkyThroughTunnelMove");
		MoveThroughTunnelDistance += DeltaTime * MoveThroughTunnelSpeed;
		FVector NewPos = SlinkyTunnel.GuideSpline.GetLocationAtDistanceAlongSpline(MoveThroughTunnelDistance, ESplineCoordinateSpace::World);

		if (Player == Game::GetCody())
			NewPos += SlinkyTunnel.GuideSpline.GetUpVectorAtDistanceAlongSpline(MoveThroughTunnelDistance, ESplineCoordinateSpace::World) * 100.f;
		else
			NewPos += SlinkyTunnel.GuideSpline.GetUpVectorAtDistanceAlongSpline(MoveThroughTunnelDistance, ESplineCoordinateSpace::World) * -100.f;
			
		FVector Delta = NewPos - Player.GetActorLocation();
		
		if (!ThroughTunnelFrameMove.ContainsNaN())
			ThroughTunnelFrameMove.ApplyDelta(Delta);

		if (MoveThroughTunnelDistance >= SlinkyTunnel.GuideSpline.GetSplineLength())
			SlinkyMovementState = ESlinkyMovementState::Finished;

		return ThroughTunnelFrameMove; 
	}

	void ChangeFieldOfView(float FovLerp)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.f;
		Player.ApplyFieldOfView(FMath::Lerp(70.f, 135.f, FovLerp), Blend, this);
	}

	void SetCameraPointOfInterest()
	{
		FHazePointOfInterest PointOfInterest;
		FVector NewPointOfInterestLocation = SlinkyTunnel.GuideSpline.GetLocationAtDistanceAlongSpline(MoveThroughTunnelDistance + 500.f, ESplineCoordinateSpace::World);
		PointOfInterest.FocusTarget.WorldOffset = NewPointOfInterestLocation;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterest.Blend.BlendTime = 0.5f;
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.5f;
		Player.ApplyPivotOffset(FVector::ZeroVector, Blend, this);
		Player.ApplyCameraOffsetOwnerSpace(FVector::ZeroVector, Blend, this);

		Player.ApplyPointOfInterest(PointOfInterest, this);
	}

	void SetStartMovementPointOfInterest()
	{
		FHazePointOfInterest PointOfInterest;
		FVector NewPointOfInterestLocation = SlinkyTunnel.GuideSpline.GetLocationAtDistanceAlongSpline(MoveThroughTunnelDistance + 150.f, ESplineCoordinateSpace::World);
		PointOfInterest.FocusTarget.WorldOffset = NewPointOfInterestLocation;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterest.Blend.BlendTime = 1.5f;
		
		Player.ApplyPointOfInterest(PointOfInterest, this);
	}
}