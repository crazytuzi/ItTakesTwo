import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Foghorn.FoghornStatics;
class UPlayerFoghornCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Audio");
	default CapabilityTags.Add(n"Foghorn");
	default CapabilityDebugCategory = n"Audio";

	AHazePlayerCharacter PlayerOwner;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsPlayerDead(PlayerOwner))
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsPlayerDead(PlayerOwner))
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// TODO: Is PlayerOwner correct to use here?
		UFoghornBarkDataAsset DefaultBark = UFoghornManagerComponent::Get(PlayerOwner).DefaultTransitionBarkDataAsset;
		if (DefaultBark != nullptr)
		{
			ResumeFoghornWithBark(PlayerOwner, DefaultBark, nullptr);
		}
		else
		{
			ResumeFoghornActor(PlayerOwner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// TODO: Is PlayerOwner correct to use here?
		// Philip Eriksson: Removed Pause to be able to play death effort for Cody and May
		//PauseFoghornActor(PlayerOwner);
	}
}