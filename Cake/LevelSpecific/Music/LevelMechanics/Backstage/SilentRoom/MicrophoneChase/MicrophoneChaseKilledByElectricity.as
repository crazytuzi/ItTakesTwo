import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseElectricity;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent;

class UMicrophoneChaseKilledByElectricity : UHazeCapability
{
	default CapabilityTags.Add(n"MicrophoneChaseKilledByElectricity");

	default CapabilityDebugCategory = n"MicrophoneChaseKilledByElectricity";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UMicrophoneChaseElectricityContainerComponent ElectricityContainer;
	UCharacterMicrophoneChaseComponent ChaseComp;

	private bool bKillPlayer = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ElectricityContainer = UMicrophoneChaseElectricityContainerComponent::GetOrCreate(Player);
		ChaseComp = UCharacterMicrophoneChaseComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(Electricity == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Player.IsPlayerDead())
			return EHazeNetworkActivation::DontActivate;

		if(ChaseComp.bQuicktimeEvent)
			return EHazeNetworkActivation::DontActivate;

		if(ChaseComp.bMicrophoneChaseDone)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Electricity == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bKillPlayer)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(ChaseComp.bQuicktimeEvent)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(ChaseComp.bMicrophoneChaseDone)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bKillPlayer = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bKillPlayer && !Player.IsPlayerDead())
		{
			KillPlayer(Player, ChaseComp.ElectricityDeathFX);
			Electricity.HazeAkComp.HazePostEvent(Electricity.KillElectricityEvent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		bKillPlayer = Electricity.CurrentElectricityOffset < 10.0f;
	}

	private AMicrophoneChaseElectricity GetElectricity() const property { return ElectricityContainer.Electricity; }
}