import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatStreamComponent;
import Peanuts.Spline.SplineComponent;


class UWheelBoatSubActorStreamMovementCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WheelBoat");
	default CapabilityTags.Add(n"WheelBoatMovement");

    default TickGroup = ECapabilityTickGroups::ReactionMovement;

	AWheelBoatActorWheelActor SubActor;
	UWheelBoatStreamComponent StreamComponent;
	AWheelBoatActor WheelBoat;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		SubActor = Cast<AWheelBoatActorWheelActor>(Owner);
		WheelBoat = SubActor.ParentBoat;
		StreamComponent = WheelBoat.StreamComponent;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(WheelBoat.bDocked)
            return EHazeNetworkActivation::DontActivate;;

		if(WheelBoat.PlayerInLeftWheel == nullptr && WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.IsInBossFight())
            return EHazeNetworkActivation::DontActivate;

		if(!WheelBoat.IsInStream())
			return EHazeNetworkActivation::DontActivate;
        
    	return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(WheelBoat.bDocked)
            return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.PlayerInLeftWheel == nullptr && WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.IsInBossFight())
            return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(!WheelBoat.IsInStream())
			return EHazeNetworkDeactivation::DeactivateLocal;
      
        return EHazeNetworkDeactivation::DontDeactivate;
    }
	
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(HasControl())
		{
			// We apply this sides players input
			{	
				FWheelBoatMovementData& MovementData = SubActor.MovementData;

				ApplyDrag(MovementData, DeltaTime);	
				AddAcceleration(MovementData, DeltaTime);
				MovementData.Finalize(DeltaTime);
			}

			// If we are playing network, we also apply the other players replicated input to this side
			// If we are not playing network, both sides are handled locally
			if (Network::IsNetworked())
			{
				//FVector FinalVelocity = BoatVelocity;
				FWheelBoatMovementData& OtherMovementData = SubActor.OtherSubActor.MovementData;
				ApplyDrag(OtherMovementData, DeltaTime);
				AddAcceleration(OtherMovementData, DeltaTime);
				OtherMovementData.Finalize(DeltaTime);
			}
		}
    }

	void AddAcceleration(FWheelBoatMovementData& MovementData, float DeltaTime)
	{
		UBoatSettingsDataAsset BoatSettings = WheelBoat.BoatSettings;
		const FVector ForwardVector = WheelBoat.ActorForwardVector;
		const FVector RightVector = WheelBoat.ActorRightVector;
		const FVector CurrentStreamDirection = WheelBoat.StreamComponent.StreamDirection;

		const FVector WantedStreamVelocity = CurrentStreamDirection * WheelBoat.StreamComponent.StreamMovementForce * 0.25f;
		const FVector WantedBoatVelocity = ForwardVector * MovementData.WheelMovementRange * BoatSettings.StreamMovementBonusSpeed;

		const float WheelRangeMinValue = 0.25f;
		if(MovementData.WheelMovementRange > WheelRangeMinValue)
		{
			const float VelocityAlpha = FMath::Lerp(0.f, BoatSettings.StreamForwardMaxIngore, MovementData.WheelMovementRange);
			FVector WantedVelocity = FMath::Lerp(WantedStreamVelocity, WantedStreamVelocity + WantedBoatVelocity, VelocityAlpha);
			MovementData.BoatVelocity = FMath::VInterpTo(MovementData.BoatVelocity, WantedVelocity, DeltaTime, BoatSettings.StreamAccelerationSpeed);
		}
		else if(MovementData.WheelMovementRange < -WheelRangeMinValue)
		{
			const float VelocityAlpha = FMath::Lerp(0.f, BoatSettings.StreamBackwardMaxIngore, FMath::Abs(MovementData.WheelMovementRange));
			FVector WantedVelocity = FMath::Lerp(WantedStreamVelocity, FVector::ZeroVector, VelocityAlpha);
			MovementData.BoatVelocity = FMath::VInterpTo(MovementData.BoatVelocity, WantedVelocity, DeltaTime, BoatSettings.StreamNormalizeSpeed);
		}
		else
		{
			MovementData.BoatVelocity = FMath::VInterpTo(MovementData.BoatVelocity, WantedStreamVelocity, DeltaTime, BoatSettings.StreamDecelerationSpeed);
		}	

		MovementData.BoatAngularVelocity.Yaw += MovementData.WheelMovementRange * DeltaTime * WheelBoat.GetAngularAcceleration();	
	}

	void ApplyDrag(FWheelBoatMovementData& MovementData, float DeltaTime)
	{
		UBoatSettingsDataAsset BoatSettings = WheelBoat.BoatSettings;

		MovementData.BoatAngularVelocity -= MovementData.BoatAngularVelocity * DeltaTime * BoatSettings.AngularDrag; 
	}
}