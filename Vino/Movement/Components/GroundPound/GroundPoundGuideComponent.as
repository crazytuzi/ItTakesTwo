import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import void RequestGroundPoundGuideCapability() from "Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundGuidedEnterCapability";
import void UnrequestGroundPoundGuideCapability() from "Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundGuidedEnterCapability";
import void RequestGroundPoundGuideEvaluateCapability() from "Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundGuideEvaluateCapability";
import void UnrequestGroundPoundGuideEvaluateCapability() from "Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundGuideEvaluateCapability";

class UGroundPoundGuideComponent : USceneComponent
{
	// If the player is within this radius when starting to groundpound then it will be guided
	UPROPERTY()
	float ActivationRadius = 200.f;

	// If the Player is even furthen in at this radius then we don't trigger the guide.
	UPROPERTY()
	float TargetRadius = 100.f;

	// The player needs to be this height above the actor to trigger.
	UPROPERTY()
	float MinHeightAboveActor = 200.f;

	UPROPERTY()
	bool bGuidingEnabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RequestGroundPoundGuideEvaluateCapability();
		RequestGroundPoundGuideCapability();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndReason)
	{
		UnrequestGroundPoundGuideCapability();
		UnrequestGroundPoundGuideEvaluateCapability();
	}

	UFUNCTION()
	void EnableGuiding()
	{
		bGuidingEnabled = true;
	}

	UFUNCTION()
	void DisableGuiding()
	{
		bGuidingEnabled = false;
	}

	float GetOuterRadius() const property
	{
		return ActivationRadius;
	}

	float GetInnerRadius() const property
	{
		return TargetRadius;
	}

	float GetVolumeHeight() property
	{
		return RelativeLocation.Z - MinHeightAboveActor;
	}

	float GetFullHeight() property
	{
		return RelativeLocation.Z;
	}

	bool RadiusIsValid()
	{
		return OuterRadius > InnerRadius;
	}

	bool HeightsAreValid()
	{
		return (RelativeLocation.Z > 5.f) && (RelativeLocation.Z > MinHeightAboveActor);
	}

	bool HelperVolumeIsValid()
	{
		return RadiusIsValid() && HeightsAreValid() && bGuidingEnabled;
	}

	void RenderVolume(FLinearColor Color, float LifeTime)
	{
		float HalfHeight = (VolumeHeight / 2.f);
		FVector CapsuleLoc = WorldLocation - Owner.ActorRotation.UpVector * HalfHeight;

		Debug::DrawDebugCylinder(CapsuleLoc, Owner.ActorRotation, ActivationRadius, HalfHeight, Color, 0.f, 32, false, LifeTime);
	}

	bool LocationIsWithinActivationRegionOfVolume(FVector Location, FVector WorldUp, bool bDebug)
	{
		FVector LinePoint = FMath::ClosestPointOnLine(WorldLocation, WorldLocation - (WorldUp * VolumeHeight), Location);

		FVector DeltaToPoint = LinePoint - Location;

		if (FMath::Abs(DeltaToPoint.SafeNormal.DotProduct(WorldUp)) > 0.3f)
		{
			if (bDebug)
				System::DrawDebugLine(Location, LinePoint, FLinearColor::Red);

			return false;
		}
		
		if (DeltaToPoint.Size() > OuterRadius)
		{
			if (bDebug)
				System::DrawDebugLine(Location, LinePoint, FLinearColor::Purple);
				
			return false;
		}
		
		if (DeltaToPoint.Size() > InnerRadius)
		{
			if (bDebug)
				System::DrawDebugLine(Location, LinePoint, FLinearColor::Green);

			return true;
		}

		if (bDebug)
			System::DrawDebugLine(Location, LinePoint, FLinearColor::Teal);

		return false;
	}
}

class UGroundPoundTargetHelperComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UGroundPoundGuideComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UGroundPoundGuideComponent Comp = Cast<UGroundPoundGuideComponent>(Component);
		if (Comp == nullptr)
			return;

		if (Comp.IsRooted)
			return;

		FRotator Rotation = Comp.Owner.ActorRotation;
		if (!Comp.HeightsAreValid())
		{
			ErrorDraw(Comp.WorldLocation, Rotation, Comp.VolumeHeight, Comp.ActivationRadius);
			return;
		}

		float TriggerHeight = Comp.VolumeHeight;
		FLinearColor OuterColor = Comp.RadiusIsValid() ? FLinearColor::Teal : FLinearColor::Purple;
		RenderCylinderVolume(Comp.WorldLocation, Rotation, TriggerHeight, Comp.OuterRadius, OuterColor);

		FLinearColor InnerColor = Comp.RadiusIsValid() ? FLinearColor::Green : FLinearColor::Red;
		RenderCylinderVolume(Comp.WorldLocation, Rotation, TriggerHeight, Comp.InnerRadius, InnerColor);

		FHazeTraceParams Trace;
		Trace.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		Trace.From = Comp.WorldLocation;
		Trace.To = Trace.From + -Rotation.UpVector * Comp.FullHeight;

		FHazeHitResult Hit;
		if (Trace.Trace(Hit))
			DrawWireSphere(Hit.ImpactPoint, Comp.InnerRadius, InnerColor, 1.f, 16);
		else
			DrawLine(Trace.From, Trace.To, FLinearColor::Red);
	}

	void RenderCylinderVolume(FVector Location, FRotator Rotation, float VolumeHeight, float Radius, FLinearColor Color)
	{
		float HalfHeight = (VolumeHeight / 2.f);
		FVector CapsuleLoc = Location - Rotation.UpVector * HalfHeight;

		DrawWireCylinder(CapsuleLoc, Rotation, Color, Radius, HalfHeight, 32);
	}

	void ErrorDraw(FVector Location, FRotator Rotation, float VolumeHeight, float Radius)
	{
		float HalfHeight = (FMath::Abs(VolumeHeight) / 2.f);
		FVector CapsuleLoc = Location - (Rotation.UpVector * HalfHeight) * FMath::Sign(VolumeHeight);

		DrawWireCylinder(CapsuleLoc, Rotation, FLinearColor::Red, Radius, HalfHeight, 32);
	}
}

