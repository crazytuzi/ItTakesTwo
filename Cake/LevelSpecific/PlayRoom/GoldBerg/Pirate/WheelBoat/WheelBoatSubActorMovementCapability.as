import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatStreamComponent;
import Peanuts.Spline.SplineComponent;


class UWheelBoatSubActorMovementCapability : UHazeCapability
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

		if(WheelBoat.UseBossFightMovement())
            return EHazeNetworkActivation::DontActivate;

		if(WheelBoat.IsInStream())
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

		if(WheelBoat.UseBossFightMovement())
            return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(WheelBoat.IsInStream())
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
		const FVector ForwardVector = WheelBoat.ActorForwardVector;
		UBoatSettingsDataAsset BoatSettings = WheelBoat.BoatSettings;
		
		MovementData.BoatVelocity += ForwardVector * MovementData.WheelMovementRange * BoatSettings.AccelerationSpeed * DeltaTime;
		MovementData.BoatAngularVelocity.Yaw += MovementData.WheelMovementRange * DeltaTime * WheelBoat.GetAngularAcceleration();	
	}

	void ApplyDrag(FWheelBoatMovementData& MovementData, float DeltaTime)
	{
		const FVector ForwardVector = WheelBoat.ActorForwardVector;
		const FVector RightVector = WheelBoat.ActorRightVector;
		UBoatSettingsDataAsset BoatSettings = WheelBoat.BoatSettings;

		FVector ForwardVelocity = ForwardVector * MovementData.BoatVelocity.DotProduct(ForwardVector);		
		MovementData.BoatVelocity -= ForwardVelocity * DeltaTime * BoatSettings.ForwardDrag * 1.3f;

		FVector RightVelocity = RightVector * MovementData.BoatVelocity.DotProduct(RightVector);
		MovementData.BoatVelocity -= RightVelocity * DeltaTime * BoatSettings.RightDrag * 1.3f;

		MovementData.BoatAngularVelocity -= MovementData.BoatAngularVelocity * DeltaTime * BoatSettings.AngularDrag; 
	}
}