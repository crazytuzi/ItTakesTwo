import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.UserGrindGrappleComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Grinding.GrindingActivationPointComponent;
import Vino.Movement.Grinding.GrindingReasons;

class UCharacterGrindingGrappleEvaluateCapability : UCharacterMovementCapability
{
	default RespondToEvent(GrindingActivationEvents::PotentialGrinds);
	default RespondToEvent(n"GrindForceActivate");

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Grapple);
	default CapabilityTags.Add(GrindingCapabilityTags::GrappleEvaluate);
	default CapabilityTags.Add(GrindingCapabilityTags::Evaluate);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UUserGrindGrappleComponent GrappleComp;
	UGrindingActivationComponent ActivationPoint;

	FGrindSplineData GrappleGrindSplineData;
	bool bForceGrapple = false;

	FVector InterpedTestLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		GrappleComp = UUserGrindGrappleComponent::GetOrCreate(Owner);
		ActivationPoint = UGrindingActivationComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{
		bool bUsingActivationPoint = UpdateActivationPoint();

		// Disable activation point if we aren't using it
		if (!bUsingActivationPoint && ActivationPoint.ValidationType != EHazeActivationPointActivatorType::None)
			ActivationPoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}

	bool UpdateActivationPoint()
	{
		if (IsBlocked())
			return false;
			
		if (IsActive())
			return false;
		
		if (UserGrindComp.HasTargetGrindSpline())
			return false;

		if (UserGrindComp.HasActiveGrindSpline())
			return false;

		return EvaluateGrappleLocation(Player.ActorDeltaSeconds);
    }

	bool EvaluateGrappleLocation(float DeltaTime)
	{		
		GrappleGrindSplineData.Reset();
		ActivationPoint.bHasPotentialTarget = false;

		// Test and store the forced grapple data
		UObject ForcedGrappleObject;
		float ForcedDistanceAlongSpline = 0.f;

		if (ConsumeAttribute(n"GrindForceGrappleGrindSpline", ForcedGrappleObject))
			ConsumeAttribute(n"GrindForceGrappleDistance", ForcedDistanceAlongSpline);

		AGrindspline ForcedGrappleGrindSpline = Cast<AGrindspline>(ForcedGrappleObject);

		if (ForcedGrappleGrindSpline != nullptr)
		{
			GrappleGrindSplineData = UserGrindComp.GetGrindSplineDataFromDistanceAlongSpline(ForcedGrappleGrindSpline, ForcedDistanceAlongSpline);
			bForceGrapple = true;
			return false;
		}

		// Calculate where the test should be taken
		FVector TargetTestLocation = Player.ActorLocation;
		
		FVector CameraToPlayer = Owner.ActorLocation - Player.ViewLocation;
		float Length = Player.ViewRotation.ForwardVector.DotProduct(CameraToPlayer);
		
		TargetTestLocation += MoveComp.WorldUp * 500.f;
		TargetTestLocation += Player.ViewRotation.ForwardVector * 1200.f;

		InterpedTestLocation = FMath::VInterpTo(InterpedTestLocation, TargetTestLocation, DeltaTime, 16.f);

		FVector TestLocation = InterpedTestLocation;

		
		if (IsDebugActive())
			System::DrawDebugSphere(TestLocation, 25.f, 8.f, FLinearColor::Green, 0.f, 3.f);

		GrappleGrindSplineData = GetBestPotentialGrappleableSpline(TestLocation);
		if (GrappleGrindSplineData.GrindSpline == nullptr)
			return false;
			
		GrappleGrindSplineData.ReverseTowardsTravelDirection();

		// Find a new test location if you are looking backwards in a one directional spline
		FVector PlayerToSpline = GrappleGrindSplineData.SystemPosition.GetWorldLocation() - Owner.ActorLocation;
		if (GrappleGrindSplineData.GrindSpline.TravelDirection != EGrindSplineTravelDirection::Bidirectional && PlayerToSpline.DotProduct(GrappleGrindSplineData.SystemPosition.WorldForwardVector) < 0.f)
		{
			PlayerToSpline = PlayerToSpline.ConstrainToPlane(GrappleGrindSplineData.SystemPosition.WorldForwardVector);			
			if (IsDebugActive())
				System::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + PlayerToSpline, FLinearColor::LucBlue, 0.f, 3.f);

			// Find a new test location by finding the average between the nearest point, and the original grapple location
			float PlayerDistancePct = PlayerToSpline.Size() / GrappleGrindSplineData.GrindSpline.GrappleRange;
			FVector ToGrappleLocation = GrappleGrindSplineData.SystemPosition.GetWorldLocation() - (Player.ActorLocation + PlayerToSpline);
			FVector NewTestLocation = Player.ActorLocation + PlayerToSpline + (ToGrappleLocation * PlayerDistancePct);

			// Calculate a new spline position
			FVector ExcludePlaneLocation = Player.ViewLocation;
			FVector ExcludePlaneDirection = Player.ViewRotation.ForwardVector;
			float DistanceAlongSpline = 0.f;

			if (GrappleGrindSplineData.GrindSpline.Spline.FindDistanceAlongSplineAtWorldLocationExcludePlane(NewTestLocation, DistanceAlongSpline, ExcludePlaneLocation, ExcludePlaneDirection))
			{
				FHazeSplineSystemPosition NewPosition;
				NewPosition.FromData(GrappleGrindSplineData.GrindSpline.Spline, DistanceAlongSpline, GrappleGrindSplineData.SystemPosition.IsForwardOnSpline());

				GrappleGrindSplineData = FGrindSplineData(GrappleGrindSplineData.GrindSpline, NewPosition);
			}
		}

		// Move the point forwards or backwards if the current position is within the margins at either end
		if (!GrappleGrindSplineData.GrindSpline.Spline.IsClosedLoop() &&
			GrappleGrindSplineData.GrindSpline.GrappleBlockMarginStart > 0.f &&
			GrappleGrindSplineData.SystemPosition.DistanceAlongSpline < GrappleGrindSplineData.GrindSpline.GrappleBlockMarginStart)
		{			
			float Delta = GrappleGrindSplineData.GrindSpline.GrappleBlockMarginStart - GrappleGrindSplineData.SystemPosition.DistanceAlongSpline;
			if (!GrappleGrindSplineData.SystemPosition.IsForwardOnSpline())
				Delta *= -1;
			GrappleGrindSplineData.SystemPosition.Move(Delta);
		}
		else if (!GrappleGrindSplineData.GrindSpline.Spline.IsClosedLoop() &&
			GrappleGrindSplineData.GrindSpline.GrappleBlockMarginEnd > 0.f &&
			(GrappleGrindSplineData.SystemPosition.Spline.GetSplineLength() - GrappleGrindSplineData.SystemPosition.DistanceAlongSpline) < GrappleGrindSplineData.GrindSpline.GrappleBlockMarginEnd)
		{
			float Delta = GrappleGrindSplineData.SystemPosition.Spline.GetSplineLength() - GrappleGrindSplineData.GrindSpline.GrappleBlockMarginEnd;
			Delta -= GrappleGrindSplineData.SystemPosition.DistanceAlongSpline;
			if (!GrappleGrindSplineData.SystemPosition.IsForwardOnSpline())
				Delta *= -1;
			GrappleGrindSplineData.SystemPosition.Move(Delta);
		}
			
		if (IsDebugActive())
			System::DrawDebugLine(Player.ActorLocation, GrappleGrindSplineData.SystemPosition.WorldLocation, FLinearColor::Green, 0.f, 6.f);

		if (IsDebugActive())
			System::DrawDebugSphere(GrappleGrindSplineData.SystemPosition.GetWorldLocation(), 25.f, 8.f, FLinearColor::Red, 0.f, 3.f);
		
		ActivationPoint.bHasPotentialTarget = true;
		UserGrindComp.UpdateTargetPointLocation(GrappleGrindSplineData.SystemPosition.WorldLocation);

		FVector HeightOffset = GrappleGrindSplineData.SystemPosition.WorldUpVector * GrappleGrindSplineData.GrindSpline.HeightOffset;
		ActivationPoint.SetWorldLocation(UserGrindComp.TargetPointLocation + HeightOffset);
		if (ActivationPoint.AttachParent != GrappleGrindSplineData.GrindSpline.RootComponent)
			ActivationPoint.MakeUnavailableToNextFrame();

		ActivationPoint.AttachTo(GrappleGrindSplineData.GrindSpline.RootComponent, NAME_None, EAttachLocation::KeepWorldPosition, true);
		ActivationPoint.InitializeDistances(
			GrappleGrindSplineData.GrindSpline.GrappleRange + 2000.f,
			GrappleGrindSplineData.GrindSpline.GrappleRange + 1000.f,
			GrappleGrindSplineData.GrindSpline.GrappleRange
		);

		if (ActivationPoint.ValidationType == EHazeActivationPointActivatorType::None)
			ActivationPoint.ChangeValidActivator(Player.IsCody() ? EHazeActivationPointActivatorType::Cody : EHazeActivationPointActivatorType::May);

		Player.UpdateActivationPointAndWidgets(UGrindingActivationComponent::StaticClass());

		if (!ActivationPoint.IsTargetedBy(Player))
			GrappleGrindSplineData.Reset();

		return true;
	}	

	FGrindSplineData GetBestPotentialGrappleableSpline(FVector TestLocation)
	{
		/*
			In range grapple points should score higher than out of range (not just distance based)
		*/
		FGrindSplineData GrindSplineLocationData;
		float Distance = BIG_NUMBER;

		for (AGrindspline PotentialGrindSpline : UserGrindComp.ValidNearbyGrindSplines)
		{
			if (!PotentialGrindSpline.bCanGrappleTo)
				continue;

			if (!PotentialGrindSpline.bGrindingAllowed)
				continue;

			//Find target behind plane
			FVector ExcludePlaneLocation = Player.ViewLocation;
			FVector ExcludePlaneDirection = Player.ViewRotation.ForwardVector;

			float DistanceAlongSpline = 0.f;
			if (!PotentialGrindSpline.Spline.FindDistanceAlongSplineAtWorldLocationExcludePlane(TestLocation, DistanceAlongSpline, ExcludePlaneLocation, ExcludePlaneDirection))
				continue;
			FHazeSplineSystemPosition PotentialPosition;
			PotentialPosition.FromData(PotentialGrindSpline.Spline, DistanceAlongSpline, true);

			FVector ToPotentialPosition = PotentialPosition.WorldLocation - TestLocation;
			float PotentialDistance = ToPotentialPosition.Size();

			bool bBestHasLowPriority = false;
			
			if (IsDebugActive())
				System::DrawDebugLine(Player.ActorLocation, PotentialPosition.WorldLocation, FLinearColor(1.f, 0.3f, 0.f), 0.f, 3.f);

			// Set as current best spline if distance is nearer
			if (GrindSplineLocationData.GrindSpline == nullptr)
			{
				GrindSplineLocationData.SystemPosition = PotentialPosition;
				GrindSplineLocationData.GrindSpline = PotentialGrindSpline;
				Distance = PotentialDistance;

				for (FGrindSplineCooldown Cooldown : UserGrindComp.GrindSplineLowPriorities)
				{
					if (Cooldown.GrindSpline == GrindSplineLocationData.GrindSpline)
					{
						bBestHasLowPriority = true;
						break;
					}
				}
			}
			else
			{				
				bool bPotentialHasLowPriority = false;

				for (FGrindSplineCooldown Cooldown : UserGrindComp.GrindSplineLowPriorities)
				{
					if (Cooldown.GrindSpline == PotentialGrindSpline)
					{
						bPotentialHasLowPriority = true;
						break;
					}
				}

				bool bPotentialIsNearer = PotentialDistance < Distance;

				if (Distance > 800.f)
					bBestHasLowPriority = true;

				if (bBestHasLowPriority && !bPotentialHasLowPriority)
				{
					GrindSplineLocationData.SystemPosition = PotentialPosition;
					GrindSplineLocationData.GrindSpline = PotentialGrindSpline;
					Distance = PotentialDistance;
					bBestHasLowPriority = bPotentialHasLowPriority;
				}
				else if (bBestHasLowPriority && bPotentialHasLowPriority && bPotentialIsNearer)
				{
					GrindSplineLocationData.SystemPosition = PotentialPosition;
					GrindSplineLocationData.GrindSpline = PotentialGrindSpline;
					Distance = PotentialDistance;
					bBestHasLowPriority = bPotentialHasLowPriority;
				}
				else if (!bBestHasLowPriority && !bPotentialHasLowPriority && bPotentialIsNearer)
				{
					GrindSplineLocationData.SystemPosition = PotentialPosition;
					GrindSplineLocationData.GrindSpline = PotentialGrindSpline;
					Distance = PotentialDistance;
					bBestHasLowPriority = bPotentialHasLowPriority;
				}
			}		
		}
		
		return GrindSplineLocationData;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.HasTargetGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

		if (!GrappleGrindSplineData.SystemPosition.IsOnValidSpline())
        	return EHazeNetworkActivation::DontActivate;
			
		if (bForceGrapple)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (!WasActionStarted(ActionNames::SwingAttach))
        	return EHazeNetworkActivation::DontActivate;

		float DistanceToGrapplePoint = (GrappleGrindSplineData.SystemPosition.WorldLocation - Owner.ActorLocation).Size();
		if (DistanceToGrapplePoint > GrappleGrindSplineData.GrindSpline.GrappleRange)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UHazeSplineComponentBase SplineComp;
		float Distance = 0.f;
		bool bForward = true;
		GrappleGrindSplineData.SystemPosition.BreakData(SplineComp, Distance, bForward);
		
		AGrindspline TargetGrindSpline = GrappleGrindSplineData.GrindSpline;
		ActivationParams.AddObject(n"TargetGrindSpline", GrappleGrindSplineData.GrindSpline);
		ActivationParams.AddObject(n"TargetSplineComp", SplineComp);
		ActivationParams.AddValue(n"TargetSplineDistance", Distance);
		if (bForward)
			ActivationParams.AddActionState(n"TargetSplineForward");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		ConsumeAction(n"GrindForceActivate");
		AGrindspline GrindSpline = Cast<AGrindspline>(Params.GetObject(n"TargetGrindSpline"));
		if (GrindSpline == nullptr)
			return;

		UHazeSplineComponentBase SplineComp = Cast<UHazeSplineComponentBase>(Params.GetObject(n"TargetSplineComp"));
		if (SplineComp == nullptr)
			return;

		float Distance = Params.GetValue(n"TargetSplineDistance");
		bool bForward = Params.GetActionState(n"TargetSplineForward");

		FGrindSplineData SplineData = FGrindSplineData(GrindSpline, SplineComp, Distance, bForward);
		GrappleComp.FrameEvaluatedGrappleTarget = SplineData;

		/* Attach Effects */
		FVector GrappleWorldLocation = SplineData.SystemPosition.WorldLocation;
		if (GrindSpline.GrindingEffectsData != nullptr && GrindSpline.GrindingEffectsData.GrappleEffectAtGrapplePoint != nullptr)
			Niagara::SpawnSystemAtLocation(GrindSpline.GrindingEffectsData.GrappleEffectAtGrapplePoint, GrappleWorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		// Grapple evaluation is only valid for one frame, if nothing picks up on it just reset!
		GrappleComp.ConsumeFrameEvaluation();
		bForceGrapple = false;
	}
}
