import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Components.MovementComponent;
import Rice.Math.MathStatics;

class UCharacterGrindingSpeedCapability : UHazeCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Speed);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 180;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UHazeMovementComponent MoveComp;

	FHazeAcceleratedFloat AcceleratedSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateDesiredSpeed(DeltaTime);
		UpdateCurrentSpeed(DeltaTime);
	}

	void UpdateDesiredSpeed(float DeltaTime)
	{	
		float SpeedOverride = 0.f;
		ConsumeAttribute(n"GrindingSpeedOverride", SpeedOverride);

		if (FMath::IsNearlyZero(SpeedOverride))
		{
			float SlopePercentage = Math::GetPercentageBetweenClamped(0.f, GrindSettings::Speed.SlopeTerminalAngle, FMath::Abs(CurrentSlopeAngle)) * FMath::Sign(CurrentSlopeAngle);

			float DesiredAcceleration = 0.f;			
			if (FMath::Abs(CurrentSlopeAngle) <= GrindSettings::Speed.SlopeAngleConsideredFlat)
			{
				float SpeedToDesired = DesiredSpeed - UserGrindComp.BasicSpeedSettings.DesiredMiddle;
				float FlatAcceleration = FMath::Sign(SpeedToDesired) * GrindSettings::Speed.DesiredSlopeDeceleration;

				if (FMath::Abs(SpeedToDesired) < FMath::Abs(FlatAcceleration))
					FlatAcceleration = SpeedToDesired;
				
				DesiredAcceleration = FlatAcceleration * DeltaTime;
			}
			else if (SlopePercentage < 0.f)
			{
				if (DesiredSpeed <= UserGrindComp.BasicSpeedSettings.DesiredMaximum)
					DesiredAcceleration = GrindSettings::Speed.DesiredSlopeAcceleration * SlopePercentage * DeltaTime;
			}
			else
			{
				DesiredAcceleration = GetMappedRangeValueClamped(0.f, 1.f,  GrindSettings::Speed.DesiredNeutralDeceleration, GrindSettings::Speed.DesiredSlopeDeceleration, SlopePercentage) * DeltaTime;
			}
			
			UserGrindComp.DesiredSpeed = FMath::Clamp(DesiredSpeed - DesiredAcceleration, UserGrindComp.BasicSpeedSettings.DesiredMinimum, UserGrindComp.BasicSpeedSettings.DesiredMaximum);
		}
		else
			UserGrindComp.DesiredSpeed = SpeedOverride;

	}

	void UpdateCurrentSpeed(float DeltaTime)
	{
		float CurrentToDesired = DesiredSpeed - CurrentSpeed;
		float AccelerationToDesired = CurrentToDesired * 4.f * DeltaTime;

		if (FMath::Abs(CurrentToDesired) < FMath::Abs(AccelerationToDesired))
			AccelerationToDesired = CurrentToDesired;

		UserGrindComp.CurrentSpeed += AccelerationToDesired;
	}

	float GetCurrentSpeed() property
	{
		return UserGrindComp.CurrentSpeed;
	}

	float GetDesiredSpeed() property
	{
		return UserGrindComp.DesiredSpeed;
	}

	float GetCurrentSlopeAngle() property
	{
		if (UserGrindComp.HasActiveGrindSpline())
		{
			FVector Tangent = UserGrindComp.SplinePosition.WorldForwardVector;
			FVector SplineUp = UserGrindComp.SplinePosition.WorldUpVector.GetSafeNormal();

			FVector WorldUp = MoveComp.WorldUp;

			float SplineAndWorldUpDot = SplineUp.DotProduct(WorldUp);
			float TangentAndWorldUpDot = Tangent.DotProduct(WorldUp);

			float AngleDifference = Math::DotToDegrees(SplineAndWorldUpDot) * FMath::Sign(TangentAndWorldUpDot);
			return AngleDifference;
		}

		return 0.f;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";
		
		float SlopeAngle = CurrentSlopeAngle;
		DebugText += "--------[ Slope ] --------\n";
		if (FMath::Abs(SlopeAngle) <= GrindSettings::Speed.SlopeAngleConsideredFlat)
			DebugText += "Slope Flat [" + String::Conv_FloatToStringOneDecimal(SlopeAngle) + " degrees]\n\n";
		else if (SlopeAngle < 0.f)
			DebugText += "<Green> Slope Downhill [" + String::Conv_FloatToStringOneDecimal(SlopeAngle) + " degrees]</>\n\n";
		else
			DebugText += "<Red> Slope Downhill [" + String::Conv_FloatToStringOneDecimal(SlopeAngle) + " degrees]</>\n\n";			

		DebugText += "--------[ Speed ] --------\n";
		DebugText += "<Blue> Current Speed: </>" + String::Conv_FloatToStringOneDecimal(UserGrindComp.CurrentSpeed) + "\n";
		
		float CurrentToDesired = DesiredSpeed - CurrentSpeed;
		if (CurrentToDesired > 0.f)			
			DebugText += "<Green> Delta: </>" + String::Conv_FloatToStringOneDecimal(CurrentToDesired) + "\n";
		else if (CurrentToDesired < 0.f)
			DebugText += "<Red> Delta: </>" + String::Conv_FloatToStringOneDecimal(CurrentToDesired) + "\n";
		else
			DebugText += "<White> Delta: </>" + String::Conv_FloatToStringOneDecimal(CurrentToDesired) + "\n";

		DebugText += "<Yellow> Desired: </>" + String::Conv_FloatToStringOneDecimal(DesiredSpeed) + "\n";

		return DebugText;
	}
}

// Overrides grinding speed for one frame. Must be called on tick
UFUNCTION()
void SetGrindingSpeedOverride(AHazePlayerCharacter Player, float NewSpeed)
{
	if (Player == nullptr)
		return;
	Player.SetCapabilityAttributeValue(n"GrindingSpeedOverride", NewSpeed);
}