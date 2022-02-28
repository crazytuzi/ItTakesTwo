import Vino.Audio.Capabilities.AudioTags;
import Peanuts.Audio.AudioStatics;
import Vino.PressurePlate.PressurePlate;
import Vino.Camera.Actors.PivotCamera;

class UClockworkBullBossPlayerChargeCamerListenerCapability : UHazeCapability
{
	default CapabilityTags.Add(AudioTags::AudioListener);
	
	AHazePlayerCharacter Player;
	APressurePlate BullBossPressurePlate;
	APivotCamera ChargeCamera;

	private bool bCanActivate = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)	
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	

		UObject RawObject;
		if(ConsumeAttribute(n"BullBossPressurePlate", RawObject))
		{
			BullBossPressurePlate = Cast<APressurePlate>(RawObject);
			if(BullBossPressurePlate != nullptr)
			{
				BullBossPressurePlate.OnPressurePlateActivated.AddUFunction(this, n"OnPlateActivated");
				BullBossPressurePlate.OnPressurePlateDeactivated.AddUFunction(this, n"OnPlateDeactivated");
			}
		}	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bCanActivate)	
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        Player.BlockCapabilities(AudioTags::AudioListener, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		UObject RawObject;
		if(ConsumeAttribute(n"ChargeCamera", RawObject))
		{
			ChargeCamera = Cast<APivotCamera>(RawObject);
			FTransform ListenerOverrideTransform = FTransform(ChargeCamera.GetActorRotation(), ChargeCamera.GetActorLocation());
			Player.PlayerListener.SetWorldTransform(ListenerOverrideTransform);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bCanActivate)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Player.UnblockCapabilities(AudioTags::AudioListener, this);
	}

	UFUNCTION()
	void OnPlateActivated()
	{
		bCanActivate = true;
	}

	UFUNCTION()
	void OnPlateDeactivated()
	{
		bCanActivate = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(BullBossPressurePlate != nullptr)
		{
			BullBossPressurePlate.OnPressurePlateActivated.UnbindObject(this);
			BullBossPressurePlate.OnPressurePlateDeactivated.UnbindObject(this);
		}
	}
}