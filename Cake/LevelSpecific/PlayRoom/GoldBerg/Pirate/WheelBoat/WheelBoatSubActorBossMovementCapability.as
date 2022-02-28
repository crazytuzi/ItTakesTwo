import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatStreamComponent;
import Peanuts.Spline.SplineComponent;


class UWheelBoatSubActorBossMovementCapability : UHazeCapability
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
		if(!WheelBoat.UseBossFightMovement())
            return EHazeNetworkActivation::DontActivate;

    	return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!WheelBoat.UseBossFightMovement())
            return EHazeNetworkDeactivation::DeactivateLocal;
		
        return EHazeNetworkDeactivation::DontDeactivate;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}
	
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(HasControl())
		{
			// We apply this sides players input
			{	
				FWheelBoatMovementData& MovementData = SubActor.MovementData;

				if(WheelBoat.bSpinning)
				{
					ApplySpin(MovementData, DeltaTime);
				}
				else
				{
					ApplyDrag(MovementData, DeltaTime);	
					AddAcceleration(MovementData, DeltaTime);
				}
				
				MovementData.Finalize(DeltaTime);
			}

			// If we are playing network, we also apply the other players replicated input to this side
			// If we are not playing network, both sides are handled locally
			if (Network::IsNetworked())
			{
				//FVector FinalVelocity = BoatVelocity;
				FWheelBoatMovementData& OtherMovementData = SubActor.OtherSubActor.MovementData;
				
				if(WheelBoat.bSpinning)
				{
					ApplySpin(OtherMovementData, DeltaTime);
				}
				else
				{
					ApplyDrag(OtherMovementData, DeltaTime);
					AddAcceleration(OtherMovementData, DeltaTime);
				}
				
				OtherMovementData.Finalize(DeltaTime);
			}
		}
    }

	void AddAcceleration(FWheelBoatMovementData& MovementData, float DeltaTime)
	{
		UBoatSettingsDataAsset BoatSettings = WheelBoat.BoatSettings;
		MovementData.BoatAngularVelocity.Yaw += MovementData.WheelMovementRange * DeltaTime * WheelBoat.GetAngularAcceleration();	
	}

	void ApplyDrag(FWheelBoatMovementData& MovementData, float DeltaTime)
	{
		UBoatSettingsDataAsset BoatSettings = WheelBoat.BoatSettings;
		MovementData.BoatAngularVelocity -= MovementData.BoatAngularVelocity * DeltaTime * BoatSettings.AngularDrag;
	}

	void ApplySpin(FWheelBoatMovementData& MovementData, float DeltaTime)
	{
		float ForceToAdd = WheelBoat.CurrentSpinForce;
		const bool bToTheLeft = WheelBoat.CurrentSpinForce > 0;

		float Dir = 0;
		if(MovementData.bIsLeftActor)
		{
			if(bToTheLeft)
				Dir = 1;
			else
				Dir = -1;
		}
		else
		{
			if(bToTheLeft)
				Dir = -1;
			else
				Dir = 1;
		}

		MovementData.BoatAngularVelocity.Yaw = ForceToAdd * Dir;
	}
}