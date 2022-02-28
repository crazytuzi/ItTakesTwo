import Vino.Movement.MovementSystemTags;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideTags;
import Vino.Movement.Components.MovementComponent;

class USplineSlideCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);	
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 5;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);

		Player.CapsuleComponent.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		Player.CapsuleComponent.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (HasControl() && !IsActive())
		{
			ASplineSlideSpline SplineSlideSplineToActivate = SplineSlideComp.GetValidSplineForActivation(MoveComp, true);
			if (SplineSlideSplineToActivate != nullptr)
				SplineSlideComp.ActiveSplineSlideSpline = SplineSlideSplineToActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SplineSlideComp.ActiveSplineSlideSpline.bEnabled)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.IsGrounded() && (SplineSlideComp.ActiveRampJumps.Num() == 0))
		{
			// Longitudinal Bounds
			{
				float DistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
				FVector SplineForward = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
				FVector SplineLocation = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
				FVector SplineToPlayer = Owner.ActorLocation - SplineLocation;

				// If the player is behind the start, or after the end of the spline - return false
				float ForwardDot = SplineToPlayer.DotProduct(SplineForward);
				if (DistanceAlongSpline == 0.f && ForwardDot < 0.f)
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
				else if (DistanceAlongSpline == SplineSlideComp.ActiveSplineSlideSpline.Spline.SplineLength)
				{
					const float ForwardSpeed = Player.ActualVelocity.DotProduct(SplineForward);
					if (FMath::IsNearlyZero(ForwardSpeed, 200.f))
						return EHazeNetworkDeactivation::DeactivateUsingCrumb;

					// Allow yourself to stay active past the end of the spline, depending on margin size
					if (ForwardDot > SplineSlideComp.ActiveSplineSlideSpline.SplineEndMargin)
						return EHazeNetworkDeactivation::DeactivateUsingCrumb;
				} 
			}

			if (!SplineSlideComp.IsWithinSplineLongitudinalBounds(SplineSlideComp.ActiveSplineSlideSpline, false))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;

			if (!SplineSlideComp.IsWithinSplineVerticalBounds(SplineSlideComp.ActiveSplineSlideSpline))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;

			// Only care about lateral bounds if you aren't spline locked
			// (You should never be able to leave the spline laterally if you are locked)
			if (!SplineSlideComp.ActiveSplineSlideSpline.bLockToSplineWidth)
			{
				if (!SplineSlideComp.IsWithinSplineLateralBounds(SplineSlideComp.ActiveSplineSlideSpline))
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"ActiveSpline", SplineSlideComp.ActiveSplineSlideSpline);
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SplineSlideComp.ActiveSplineSlideSpline = Cast<ASplineSlideSpline>(ActivationParams.GetObject(n"ActiveSpline"));

		Owner.BlockCapabilities(n"BlockWhileSliding", this);

		if (SplineSlideComp.KnockdownLocomotionFeature_Cody != nullptr && Player.IsCody())
			Player.AddLocomotionFeature(SplineSlideComp.KnockdownLocomotionFeature_Cody);

		if (SplineSlideComp.KnockdownLocomotionFeature_May != nullptr && Player.IsMay())
			Player.AddLocomotionFeature(SplineSlideComp.KnockdownLocomotionFeature_May);

		SplineSlideComp.OnSlidingStarted.Broadcast(SplineSlideComp.ActiveSplineSlideSpline);
		SplineSlideComp.ActiveSplineSlideSpline.OnSlidingStarted.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		if (SplineSlideComp.KnockdownLocomotionFeature_Cody != nullptr && Player.IsCody())
			Player.RemoveLocomotionFeature(SplineSlideComp.KnockdownLocomotionFeature_May);

		if (SplineSlideComp.KnockdownLocomotionFeature_May != nullptr && Player.IsMay())
			Player.RemoveLocomotionFeature(SplineSlideComp.KnockdownLocomotionFeature_Cody);

		SplineSlideComp.OnSlidingStopped.Broadcast(SplineSlideComp.ActiveSplineSlideSpline);
		SplineSlideComp.ActiveSplineSlideSpline.OnSlidingStopped.Broadcast(Player);

		SplineSlideComp.ActiveSplineSlideSpline = nullptr;
		SplineSlideComp.JumpDestination = nullptr;

		Owner.UnblockCapabilities(n"BlockWhileSliding", this);		
	}


	UFUNCTION(NotBlueprintCallable)
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
		ASplineSlideSpline SplineSlideSpline = Cast<ASplineSlideSpline>(OtherActor);
		if (SplineSlideSpline == nullptr)
			return;

		if (OtherComponent != SplineSlideSpline.NearbySplineBox)
			return;

		SplineSlideComp.NearbySplineSlideSplines.Add(SplineSlideSpline);
	}

	UFUNCTION(NotBlueprintCallable)
    void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		ASplineSlideSpline SplineSlideSpline = Cast<ASplineSlideSpline>(OtherActor);
		if (SplineSlideSpline == nullptr)
			return;

		if (OtherComponent != SplineSlideSpline.NearbySplineBox)
			return;

		SplineSlideComp.NearbySplineSlideSplines.Remove(SplineSlideSpline);
	}
}