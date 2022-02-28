
//import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
//
//UCLASS()
//class UQueenUpdateVictimCapability : UQueenBaseCapability 
//{
//	float UpdateVictimTimeStamp = -BIG_NUMBER;
//
//	UFUNCTION(BlueprintOverride)
//	void Setup(FCapabilitySetupParams SetupParams)
//	{
//		Queen = Cast<AQueenActor>(Owner);
//		Settings = UQueenSettings::GetSettings(Queen);
//	}
//
//	UFUNCTION(BlueprintOverride)
//	EHazeNetworkActivation ShouldActivate() const
//	{
//		if (Time::GetGameTimeSince(UpdateVictimTimeStamp) <= Settings.Victim.TimeBetweenUpdates)
//			return EHazeNetworkActivation::DontActivate;
//
//		return EHazeNetworkActivation::ActivateFromControl;
//	}
//
//	UFUNCTION(BlueprintOverride)
//	EHazeNetworkDeactivation ShouldDeactivate() const
//	{
//		return EHazeNetworkDeactivation::DeactivateFromControl;
//	}
//
//	UFUNCTION(BlueprintOverride)
//	void OnActivated(FCapabilityActivationParams ActivationParams)
//	{
//		
//		//Queen.VictimComp.SwitchVictim();
//		//UpdateVictimTimeStamp = Time::GetGameTimeSeconds();
//	}
//}