import Peanuts.Audio.AudioStatics;

class UDefaultSharedListenerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AudioListener");
	default CapabilityTags.Add(n"AudioDefaultSharedListener");
	default CapabilityDebugCategory = n"Audio";

	AHazePlayerCharacter PlayerOwner;
	UHazeListenerComponent Listener;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		Listener = UHazeListenerComponent::Get(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.BlockCapabilities(n"AudioDefaultListener", this);			
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector CameraLocation = PlayerOwner.GetPlayerViewLocation();
		FRotator CameraRotation = PlayerOwner.GetPlayerViewRotation();

		FTransform CameraTrans = FTransform(CameraRotation, CameraLocation);

		Listener.SetWorldTransform(CameraTrans);
		
		if(IsDebugActive())
		{
			System::DrawDebugLine(Owner.GetActorLocation(), Listener.GetWorldLocation(), FLinearColor::LucBlue);
		}
	}	
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(n"AudioDefaultListener", this);
	}

}

