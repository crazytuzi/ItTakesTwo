import Peanuts.Audio.HazeAudioEffects.DopplerEffect;

class UDopplerDataComponent : UActorComponent
{
	UHazeAkComponent HazeAkOwner;

	UPROPERTY(NotVisible)
	UDopplerEffect DopplerInstance;

	UPROPERTY()
	bool bStartEnabled = true;

	UPROPERTY()
	bool bSetDopplerRTPC = true;		

	UPROPERTY(meta = (EditCondition = "bSetDopplerRTPC"))
	float MaxSpeed = 2500.f;
	UPROPERTY(meta = (EditCondition = "bSetDopplerRTPC"))
	float MinDistance = 1000.f;
	UPROPERTY(meta = (EditCondition = "bSetDopplerRTPC"))
	float MaxDistance = 0.f;
	UPROPERTY(meta = (EditCondition = "bSetDopplerRTPC"))
	float Scale = 1.f;
	UPROPERTY(meta = (EditCondition = "bSetDopplerRTPC"))
	float Smoothing = 0.5f;
	UPROPERTY(meta = (EditCondition = "bSetDopplerRTPC"))
	float CurvePower = 1.f;

	UPROPERTY()
	TArray<FDopplerPassbyEvent> PassbyEvents;

	UPROPERTY()
	EHazeDopplerObserverType ObserverType = EHazeDopplerObserverType::ClosestListener;

	UPROPERTY()
	EHazeDopplerDriverType DriverType = EHazeDopplerDriverType::Emitter;

	bool bShouldTickDoppler = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{			
		HazeAkOwner = UHazeAkComponent::GetOrCreate(Owner);
		DopplerInstance = Cast<UDopplerEffect>(HazeAkOwner.AddEffect(UDopplerEffect::StaticClass(), false, bStartEnabled));
		
		DopplerInstance.SetObjectDopplerValues(bSetDopplerRTPC, MaxSpeed, MinDistance, MaxDistance, Scale, Smoothing, CurvePower, ObserverType, DriverType);
	
		// Allow this component to tick the doppler effect in place of the HazeAkOwner, saving us the need of keeping the HazeAkOwner as active
		if(HazeAkOwner.ActiveEventInstances.Num() == 0 && 
			HazeAkOwner.AddedEffects.Num() == 1)
		{
			bShouldTickDoppler = true;
		}
		else 
		{
			SetComponentTickEnabled(false);
		}

		for(FDopplerPassbyEvent PassbyEvent : PassbyEvents)
		{
			DopplerInstance.PlayPassbySound(PassbyEvent.Event, PassbyEvent.ApexTime, PassbyEvent.Cooldown, PassbyEvent.MaxDistance, PassbyEvent.VelocityAngle, PassbyEvent.MinRelativeSpeed);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		if(bShouldTickDoppler && !HazeAkOwner.IsComponentTickEnabled())
			DopplerInstance.TickEffect(DeltaSeconds);		
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlay)
	{
		HazeAkOwner.RemoveEffect(DopplerInstance);		
	}
}