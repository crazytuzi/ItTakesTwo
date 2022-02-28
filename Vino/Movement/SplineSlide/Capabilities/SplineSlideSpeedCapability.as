import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideSettings;
import Rice.Math.MathStatics;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.SplineSlide.SplineSlideTags;
import Vino.Movement.SplineSlide.SplineSlideSpline;

class USplineSlideSpeedCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);
	default CapabilityTags.Add(SplineSlideTags::Speed);
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
       		return EHazeNetworkActivation::DontActivate;

		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsAirborne())
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		float DistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
		FVector Tangent = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();

		SplineSlideComp.CurrentLongitudinalSpeed = Tangent.DotProduct(MoveComp.Velocity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FSplineSlideLongitudinalSettings Settings = SplineSlideComp.SplineSettings.Longitudinal;

		const float SlopeAngle = GetSplineSlopeAngle();
		const float AnglePercentage = SlopeAngle == 0.f ? 0.f : SlopeAngle / Settings.MaximumAngle;

		float DesiredSpeed = Settings.DesiredNeutralSpeed;
		if (SlopeAngle <= 0.f)
			DesiredSpeed = FMath::Lerp(Settings.DesiredNeutralSpeed, Settings.DownhillSpeed, FMath::Abs(AnglePercentage));
		else
			DesiredSpeed = FMath::Lerp(Settings.DesiredNeutralSpeed, Settings.UphillSpeed, AnglePercentage);
		DesiredSpeed *= SplineSlideComp.RubberbandScale;

		
		float Acceleration = DesiredSpeed * Settings.DragCoefficient;

		float DistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
		if (DistanceAlongSpline == SplineSlideComp.ActiveSplineSlideSpline.Spline.SplineLength)
		{
			FVector SplineForward = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
			FVector SplineLocation = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			FVector SplineToPlayer = Owner.ActorLocation - SplineLocation;
			float ForwardDot = SplineToPlayer.DotProduct(SplineForward);

			// SplineSlideComp.ActiveSplineSlideSpline.SplineEndMargin
			if (ForwardDot > 0.f)
			{
				float Percentage = FMath::Clamp(0.5f - (ForwardDot / SplineSlideComp.ActiveSplineSlideSpline.SplineEndMargin), 0.f, 1.0f);
				Acceleration *= Percentage;
			}
		}


		SplineSlideComp.CurrentLongitudinalSpeed -= SplineSlideComp.CurrentLongitudinalSpeed * Settings.DragCoefficient * DeltaTime;
		SplineSlideComp.CurrentLongitudinalSpeed += Acceleration * DeltaTime;
	}

	float GetSplineSlopeAngle()
	{
		float DistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
		FVector Tangent = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World).GetSafeNormal();
		FVector SplineUp = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		FVector Forward = Tangent;
		FVector Right = MoveComp.WorldUp.CrossProduct(Forward).GetSafeNormal();
		FVector Up = Forward.CrossProduct(Right).GetSafeNormal();

		float SplineAndWorldUpDot = Up.DotProduct(MoveComp.WorldUp);
		float TangentAndWorldUpDot = Tangent.DotProduct(MoveComp.WorldUp);

		float AngleDifference = Math::DotToDegrees(SplineAndWorldUpDot) * FMath::Sign(TangentAndWorldUpDot);
		return AngleDifference;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";
		if (SplineSlideComp.ActiveSplineSlideSpline != nullptr)
		{
			const float DistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Owner.ActorLocation);
			//const FVector SplineNearestLocation = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			const FVector SplineForward = SplineSlideComp.ActiveSplineSlideSpline.GetSplineForward(DistanceAlongSpline);
			//const FVector SplineRight = SplineSlideComp.ActiveSplineSlideSpline.GetSplineRight(DistanceAlongSpline);
			//const FVector SplineUp = SplineSlideComp.ActiveSplineSlideSpline.GetSplineUp(DistanceAlongSpline);

			FVector Velocity = MoveComp.Velocity;
			float LongitudinalSpeed = Velocity.DotProduct(SplineForward);
			float LateralSpeed = Velocity.Size() - LongitudinalSpeed;

			DebugText += "<Red> Longitudinal Speed: </>" + String::Conv_FloatToStringOneDecimal(LongitudinalSpeed) + "\n";
			DebugText += "<Green> Lateral Speed: </>" + String::Conv_FloatToStringOneDecimal(LateralSpeed) + "\n";
			DebugText += "<White> Rubberband Scale: </>" + String::Conv_FloatToStringThreeDecimal(SplineSlideComp.RubberbandScale) + "\n" + "\n";

			//DebugText += "<White> Acceleration: </>" + String::Conv_FloatToStringThreeDecimal(SplineSlideComp.RubberbandScale) + "\n" + "\n";

		}
		return DebugText;
	}
}