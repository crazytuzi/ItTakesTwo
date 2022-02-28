import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatStreamComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateOceanStreamActor;

class UWheelBoatSearchForClosestStreamCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WheelBoat");
	default CapabilityTags.Add(n"WheelBoatMovement");

    default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UWheelBoatStreamComponent StreamComponent;
	AWheelBoatActor WheelBoat;

	//TArray<APirateOceanStreamActor> PirateOceanStreamsActors;

	float BlockChangeTime = 0;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		WheelBoat = Cast<AWheelBoatActor>(Owner);
		StreamComponent = WheelBoat.StreamComponent;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if(!WheelBoat.IsInStream())
            return EHazeNetworkActivation::DontActivate;	

		if(WheelBoat.IsInBossFight())
            return EHazeNetworkActivation::DontActivate;	

		if(WheelBoat.bDocked)
            return EHazeNetworkActivation::DontActivate;	

		return EHazeNetworkActivation::ActivateLocal;
    }


    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {	
		if(!WheelBoat.IsInStream())
            return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.IsInBossFight())
            return EHazeNetworkDeactivation::DeactivateLocal;

		if(WheelBoat.bDocked)
            return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;        
    }

	UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		APirateOceanStreamActor BestStream;
	
		FVector InFrontVelocity;
		if(WheelBoat.LeftWheelSubActor.MovementData.WheelMovementRange > 0.5f)
			InFrontVelocity += WheelBoat.ActorForwardVector * (FMath::Pow(WheelBoat.LeftWheelSubActor.MovementData.WheelMovementRange, 2.f) * 100.f);

		if(WheelBoat.RightWheelSubActor.MovementData.WheelMovementRange > 0.5f)
			InFrontVelocity += WheelBoat.ActorForwardVector * (FMath::Pow( WheelBoat.RightWheelSubActor.MovementData.WheelMovementRange, 2.f) * 100.f);

		StreamComponent.UpdateDirectionUsingStreamsInRange(DeltaTime, WheelBoat.GetStreamDetectDistance(), InFrontVelocity, BestStream);

		BlockChangeTime = FMath::Max(BlockChangeTime - DeltaTime, 0.f); 
		if(HasControl() && BestStream != StreamComponent.LockedStream && BlockChangeTime <= 0)
		{
			BlockChangeTime = 2.f;
			NetChangeStream(BestStream);
		}
	}

	UFUNCTION(NetFunction)
	void NetChangeStream(APirateOceanStreamActor NewStream)
	{
		StreamComponent.LockedStream = NewStream;
		APirateOceanStreamActor BestStream;
		StreamComponent.UpdateDirectionUsingStreamsInRange(0.f, WheelBoat.GetStreamDetectDistance(), FVector::ZeroVector, BestStream);
	}
}