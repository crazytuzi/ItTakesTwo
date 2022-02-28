import Peanuts.Audio.AudioStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Audio.Capabilities.AudioTags;

class UDefaultListenerCapability : UHazeCapability
{
	default CapabilityDebugCategory = AudioTags::Audio;

	default CapabilityTags.Add(AudioTags::AudioListener);
	default CapabilityTags.Add(AudioTags::DefaultListener);

	AHazePlayerCharacter PlayerOwner;
	UHazeListenerComponent Listener;
	UHazeCameraComponent Camera;
	UHazeMovementComponent MoveComp;
	UCameraUserComponent User;

	FVector PreviousLocation;
	float PreviousDistance = 0;

	float MaxDistanceDelta = 0.25f * 100;
	float MaxDistanceFromPlayer = 5.f * 100;
	float LastCameraDistanceValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		Listener = UHazeListenerComponent::Get(Owner);	
		MoveComp = UHazeMovementComponent::Get(PlayerOwner);
		User = UCameraUserComponent::Get(PlayerOwner);
		//SetListenerSpeakerOffsets(PlayerOwner);	
	}

	void UpdateListenerTransform(float DeltaTime)
	{
		// Distance based on speed.
		float MaxSpeed = UMovementSettings::GetSettings(PlayerOwner).MoveSpeed;
		MaxSpeed = FMath::Max(MaxSpeed, SMALL_NUMBER);		
		FVector VeloVector = FVector(MoveComp.Velocity.X, 0.f, MoveComp.Velocity.Y);
		float CurrentSpeed = VeloVector.Size();
		float WantedViewRatio = FMath::Clamp(CurrentSpeed / MaxSpeed, 0.f, 1.f);

		//Distance clamp based on distance change.
		FVector EarsLocation = HazeAudio::GetEarsLocation(PlayerOwner);
		FVector CameraLocation = PlayerOwner.GetPlayerViewLocation();
		FVector CameraDirection = (CameraLocation-EarsLocation);
		CameraDirection.Normalize();

		FVector ListenerLocation = Listener.GetWorldLocation();
		//Listener location has been changed somewhere else, reset!
		if (PreviousLocation != ListenerLocation)
		{
			PreviousDistance = 0;
		}

		float WantedDistance = MaxDistanceFromPlayer * WantedViewRatio * MoveComp.ActorScale;
		float NewDistance = WantedDistance;
		float DistanceDifference = FMath::Abs(NewDistance - PreviousDistance);

		if (DistanceDifference > MaxDistanceDelta) 
		{
			NewDistance = PreviousDistance + FMath::Sign(NewDistance - PreviousDistance) * MaxDistanceDelta;
		}

		PreviousDistance = FMath::Clamp(NewDistance, SMALL_NUMBER, MaxDistanceFromPlayer * MoveComp.ActorScale);
		PreviousLocation = EarsLocation + CameraDirection * PreviousDistance;

		FRotator CameraRotation = PlayerOwner.GetPlayerViewRotation();
		FTransform ListenerTransform = FTransform(CameraRotation, PreviousLocation);
		Listener.SetWorldTransform(ListenerTransform);

		if (IsDebugActive())
		{
			Debug::DrawForegroundDebugPoint(EarsLocation + CameraDirection * WantedDistance, 10.f, FLinearColor::Red);
			Print(PlayerOwner.GetName() + " ViewRatio: " + WantedViewRatio, 0.f);
			Print(PlayerOwner.GetName() + " WantedDistance: " + WantedDistance, 0.f);
			Print(PlayerOwner.GetName() + " DistanceDifference: " + DistanceDifference, 0.f);
		}
	}

	void SetDefaultTransform()
	{
		FTransform EarsTransform = HazeAudio::GetEarsTransform(PlayerOwner);
		Listener.SetWorldTransform(EarsTransform);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetDefaultTransform();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Camera = PlayerOwner.GetCurrentlyUsedCamera();
		if (Camera != nullptr)
		{
			if (User.CanControlCamera() && User.IsCameraAttachedToPlayer())
			{
				UpdateListenerTransform(DeltaTime);
			}
			else 
			{
				HazeAudio::UpdateListenerTransform(PlayerOwner, 0.f);
			}

			if (IsDebugActive() || PlayerOwner.PlayerHazeAkComp.bDebugAudio)
			{
				HazeAudio::DebugListenerLocations(PlayerOwner);
			}		
		}
		else {
			SetDefaultTransform();
		}

		const float CameraDistanceValue = HazeAudio::GetPlayerCameraDistanceRTPCValue(PlayerOwner);
		if(CameraDistanceValue != LastCameraDistanceValue)
		{
			PlayerOwner.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterCameraDistance, CameraDistanceValue);
			LastCameraDistanceValue = CameraDistanceValue;
		}
	}
	
	void SetListenerSpeakerOffsets(AHazePlayerCharacter Player)
	{
		FHazeListenerSpeakerOffsets SpeakerOffsets = HazeAudio::GetPlayerDefaultListenerSpeakerOffsets(Player);
		Listener.SetListenerSpeakerOffsets(true, SpeakerOffsets);		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}
}