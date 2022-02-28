import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;

class UDerbyHorseCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DerbyHorse");
	default CapabilityTags.Add(n"DerbyHorseCancel");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	
	ADerbyHorseActor HorseActor;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HorseActor = Cast<ADerbyHorseActor>(GetAttributeObject(n"DerbyHorseActor"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HorseActor.bCanCancelMidGame && WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		HorseActor.OnHorseDerbyMidGameExit.Broadcast(Player);
		HorseActor.bCanCancelMidGame = false;
	}
}