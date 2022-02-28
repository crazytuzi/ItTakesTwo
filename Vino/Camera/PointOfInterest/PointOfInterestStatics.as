import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Settings.CameraPointOfInterestBehaviourSettings;

namespace FPointOfInterestStatics
{
	FRotator GetPointOfInterestLocalRotation(UCameraUserComponent User, const FHazePointOfInterest& PointOfInterest)
	{
		if (!ensure((User != nullptr) && (User.Owner != nullptr)))
			return FRotator::ZeroRotator;

		FVector ViewLocation = User.Owner.ActorLocation;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		if (Player != nullptr)
			ViewLocation = Player.GetViewLocation();
		return User.WorldToLocalRotation(GetPointOfInterestWorldRotation(User, ViewLocation, PointOfInterest));
	}
	FRotator GetPointOfInterestWorldRotation(UCameraUserComponent User, const FVector& ViewLocation, const FHazePointOfInterest& PointOfInterest)
	{
		if (PointOfInterest.bMatchFocusDirection)
		{
			// Align rotation with focus target, modified by any clamps center offset
			FHazeCameraClampSettings Clamps = PointOfInterest.Clamps; 
			if (PointOfInterest.FocusTarget.Component != nullptr)
			{
				Clamps.CenterComponent = PointOfInterest.FocusTarget.Component;
				Clamps.CenterType = EHazeCameraClampsCenterRotation::Component;
			} 
			return Clamps.GetCenterRotation(PointOfInterest.FocusTarget.Actor, User);
		}
		else
		{
			// Rotate view towards the focus target. This means the target will change over time, so blend needs to be faster to compensate
			FVector TargetPOILoc = PointOfInterest.FocusTarget.GetFocusLocation(Cast<AHazePlayerCharacter>(User.Owner));
			return (TargetPOILoc - ViewLocation).Rotation();
		}
	}

	float GetYawByTurnDirection(float POIYaw, float CurrentYaw, const FHazePointOfInterest& PointOfInterest)
	{
		float Delta = (CurrentYaw - POIYaw); // Non-normalized delta
		float ShortestPathYaw = CurrentYaw - FRotator::NormalizeAxis(Delta); 
		if (PointOfInterest.TurnDirection == EHazePointOfInterestTurnType::ShortestPath)
			return ShortestPathYaw;

		// Use shortest route if currently within clamps
		FHazeCameraClampSettings Clamps = PointOfInterest.Clamps;
		if ((Clamps.ClampYawRight > Delta) && (Clamps.ClampYawLeft > -Delta))
		 	return ShortestPathYaw;

		// Should we force turn to the right or left?
		if ((PointOfInterest.TurnDirection == EHazePointOfInterestTurnType::Right) && (Delta < 0.f))
			return POIYaw - 360.f;
		if ((PointOfInterest.TurnDirection == EHazePointOfInterestTurnType::Left) && (Delta > 0.f))
			return POIYaw + 360.f;

		return POIYaw;
	}

	FRotator ApplyTurnScaling(FRotator Rotator, FHazePointOfInterest PointOfInterest)
	{
		FRotator Result = Rotator.GetNormalized();
		Result.Yaw *= PointOfInterest.TurnScaling.Yaw;
		Result.Pitch *= PointOfInterest.TurnScaling.Pitch;
		Result.Roll *= PointOfInterest.TurnScaling.Roll;
		return Result;
	}

	struct FClearOnInput
	{
		bool bHasReleasedInput = false;
		float InputDuration = 0.f;
		float MatchedAngleDelayTime = 0.f;

		void OnActivated(bool bPauseInput, UObject Instigator, AHazePlayerCharacter Player, const UCameraPointOfInterestBehaviourSettings& Settings)
		{
			bHasReleasedInput = false;
			InputDuration = 0.f;
			MatchedAngleDelayTime = 0.f;
			if (bPauseInput)
			{
				// Set input sensitivity to zero so it'll return gradually when POI is cleared
				FHazeCameraSettings CamSettings;
				CamSettings.bUseSensitivityFactor = true;
				CamSettings.SensitivityFactor = 0.f;
				Player.ApplySpecificCameraSettings(CamSettings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), 
												   CameraBlend::Normal(Settings.InputClearSensitivityRemoveDuration), 
												   Instigator, 
												   EHazeCameraPriority::Low);	
			}
		}

		void OnDeactivated(UObject Instigator, AHazePlayerCharacter Player, const UCameraPointOfInterestBehaviourSettings& Settings)
		{
			// Return input sensitivity gradually
			const float ReturnInputSensitivityDuration = 3.f;
			FHazeCameraSettings CamSettings;
			CamSettings.bUseSensitivityFactor = true;
			Player.ClearSpecificCameraSettings(CamSettings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), 
											   Instigator, 
											   Settings.InputClearSensitivityRestoreDuration);	
		}

		bool ShouldClear(const UCameraPointOfInterestBehaviourSettings& Settings)
		{
			// Note: Input clear duration of zero should still requires one frame of input
			if (InputDuration < Settings.InputClearDuration + SMALL_NUMBER) 
				return false;
			
			if (MatchedAngleDelayTime == 0.f)
				return false;

			if (Time::GetRealTimeSeconds() < MatchedAngleDelayTime)
				return false;
			
			return true;
		}

		void Update(float DeltaTime, const FRotator& POIRot, const UCameraPointOfInterestBehaviourSettings& Settings, const FVector2D& Input, UCameraUserComponent User, AHazePlayerCharacter Player)
		{
			const float InputSqr = Input.SizeSquared();
			if ((InputSqr < FMath::Square(Settings.NoInputThreshold)) || (Settings.NoInputThreshold <= 0.f))
				bHasReleasedInput = true;

			if (MatchedAngleDelayTime == 0.f)
			{		
				// We haven't yet matched angle enough to consider clearing input,
				// check if that's changed
				FRotator ViewRot = User.WorldToLocalRotation(Player.ViewRotation);
				if ((POIRot - ViewRot).IsNearlyZero(Settings.InputClearAngleThreshold))
				{
					// Now we are close enough, set delay until we can clear POI
					MatchedAngleDelayTime = Time::GetRealTimeSeconds() + Settings.InputClearWithinAngleDelay;
				}
			}

			if (bHasReleasedInput && (InputSqr > FMath::Square(Settings.InputClearThreshold)))
			{
				// Accumulate input duration when we've stopped giving input and started again
				float TimeDilation = Player.GetActorTimeDilation();
				float UndilutedDeltaTime = (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;
				InputDuration += UndilutedDeltaTime;
			}	
			else
			{
				// Too little input, reset count
				InputDuration = 0.f;
			}
		}
	}
}
