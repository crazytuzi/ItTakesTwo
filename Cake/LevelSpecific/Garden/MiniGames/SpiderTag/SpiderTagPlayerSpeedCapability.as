import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagPlayerComp;
import Vino.Movement.MovementSettings;

UCLASS(Meta = (ComposeSettingsOnto = "UTagComposableSettings"))
class UTagComposableSettings : UHazeComposableSettings
{
	UPROPERTY()
	float MoveSpeed = 800.f;
};

class USpiderTagPlayerSpeedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SpiderTagPlayerSpeedCapability");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"TagMinigame";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USpiderTagPlayerComp PlayerComp;
	UMovementSettings MovementSettings;
	float DefaultMovespeed;
	float NewDefaultMoveSpeed;
	float FastMoveSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USpiderTagPlayerComp::Get(Player);
		MovementSettings = UMovementSettings::GetSettings(Player);

		DefaultMovespeed = MovementSettings.MoveSpeed;
		NewDefaultMoveSpeed = DefaultMovespeed * 0.88f;
		FastMoveSpeed = DefaultMovespeed * 1.12f;
		MovementSettings.MoveSpeed = NewDefaultMoveSpeed;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.bWeAreIt)
        	return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PlayerComp.bWeAreIt)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MovementSettings.MoveSpeed = NewDefaultMoveSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		MovementSettings.MoveSpeed = DefaultMovespeed;
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MovementSettings.MoveSpeed = FastMoveSpeed;
	}
}