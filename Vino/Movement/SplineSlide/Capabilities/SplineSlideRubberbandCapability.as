import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideTags;
import Vino.Movement.SplineSlide.SplineSlideSettings;
import Rice.Math.MathStatics;
import Vino.Movement.MovementSystemTags;

class USplineSlideRubberbandCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(SplineSlideTags::Rubberband);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);

	default CapabilityDebugCategory = CapabilityTags::Movement;
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
        	return EHazeNetworkActivation::DontActivate;
		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
        	return EHazeNetworkActivation::DontActivate;
		if (!SplineSlideComp.SplineSettings.Rubberbanding.bEnableRubberbanding)
        	return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{			
		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!SplineSlideComp.SplineSettings.Rubberbanding.bEnableRubberbanding)
        	return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SplineSlideComp.RubberbandScale = 1.f;

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Calculate the distance between the players
		const float OwnerDistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Player.ActorLocation);
		const float OtherDistanceAlongSpline = SplineSlideComp.ActiveSplineSlideSpline.Spline.GetDistanceAlongSplineAtWorldLocation(Player.OtherPlayer.ActorLocation);
		float DistanceBetween = OtherDistanceAlongSpline - OwnerDistanceAlongSpline;

		float Scale = FMath::Min(DistanceBetween, SplineSlideComp.SplineSettings.Rubberbanding.DistanceConsideredMaximum) / SplineSlideComp.SplineSettings.Rubberbanding.DistanceConsideredMaximum;			
		Scale = Math::GetMappedRangeValueClamped(-1.f, 1.f, SplineSlideComp.SplineSettings.Rubberbanding.MinimumScale, SplineSlideComp.SplineSettings.Rubberbanding.MaximumScale, Scale);
		Scale = FMath::Pow(Scale, SplineSlideComp.SplineSettings.Rubberbanding.PowValue);
		SplineSlideComp.RubberbandScale = Scale;
    }

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";
		DebugText += "<Blue> Acceleration Scale: </>" + String::Conv_FloatToStringThreeDecimal(SplineSlideComp.RubberbandScale) + "\n";
		float DragScale = (1 - (SplineSlideComp.RubberbandScale - 1.f));
		DebugText += "<Red> Drag Scale: </>" + String::Conv_FloatToStringThreeDecimal(DragScale) + "\n";



		
		// DebugText += "<Yellow> Soft Maximum Speed: </>" + String::Conv_FloatToStringOneDecimal(SplineSlideSettings::Speed.SoftMaximumSpeed) + "\n";
		//DebugText += "<Red> Maximum Speed: </>" + String::Conv_FloatToStringOneDecimal(SplineSlideSettings::Speed.MaximumSpeed) + "\n";

		return DebugText;
	}
}