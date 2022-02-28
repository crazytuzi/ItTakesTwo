import Peanuts.Audio.AudioStatics; 
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;

class UClockworkEvilBirdAudioCapability : UHazeCapability
{	
	AHazeSkeletalMeshActor EvilBird;
	UHazeAkComponent EvilBirdHazeAkComp;
	UDopplerEffect Doppler;	
	FVector LastLocation;

	UPROPERTY()
	UAkAudioEvent StartEvilBirdEvent;

	UPROPERTY()
	UAkAudioEvent StopEvilBirdEvent;

	UPROPERTY(Category = "Doppler")
	float MaxSpeed = 2500.f;

	UPROPERTY(Category = "Doppler")
	float Scale = 1.f;

	UPROPERTY(Category = "Doppler")
	float Smoothing = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		EvilBird = Cast<AHazeSkeletalMeshActor>(Owner);
		EvilBirdHazeAkComp = UHazeAkComponent::GetOrCreate(EvilBird);		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Doppler = Cast<UDopplerEffect>(EvilBirdHazeAkComp.AddEffect(UDopplerEffect::StaticClass()));
		Doppler.SetObjectDopplerValues(true, MaxSpeed, Scale = Scale, Smoothing = Smoothing);
		EvilBirdHazeAkComp.HazePostEvent(StartEvilBirdEvent);
		EvilBirdHazeAkComp.SetTrackVelocity(true, 6000.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		EvilBirdHazeAkComp.HazePostEvent(StopEvilBirdEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{		
		FVector WorldUp = FVector::UpVector;
		FVector CurrentLocation = EvilBird.GetActorLocation();
		FVector VeloVector = CurrentLocation - LastLocation;
		FVector ForwardVelo = VeloVector.ConstrainToPlane(WorldUp).GetSafeNormal();		

		const float Tilt = Math::DotToDegrees(VeloVector.GetSafeNormal().DotProduct(ForwardVelo));
		float NormalizedTilt = FMath::Lerp(-1.f, Math::GetPercentageBetween(0.f, 90.f, Tilt), 1.f);
		NormalizedTilt = NormalizedTilt * FMath::Sign(VeloVector.DotProduct(WorldUp));

		LastLocation = CurrentLocation;
		EvilBirdHazeAkComp.SetRTPCValue("Rtpc_Characters_Bosses_EvilBird_Tilt", NormalizedTilt);	
	}
}
