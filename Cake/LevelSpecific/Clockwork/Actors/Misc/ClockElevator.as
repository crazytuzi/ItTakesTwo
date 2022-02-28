import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;

class AClockElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ClockBase;

	UPROPERTY(DefaultComponent)
	USceneComponent HourHandBase;

	UPROPERTY(DefaultComponent, Attach = HourHandBase)
	UStaticMeshComponent HourHand;
	default HourHand.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = HourHandBase)
	UBoxComponent HourHandDeathBox;
	default HourHandDeathBox.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	USceneComponent MinuteHandBase;

	UPROPERTY(DefaultComponent, Attach = MinuteHandBase)
	UStaticMeshComponent MinuteHand;
	default MinuteHand.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = MinuteHandBase)
	UBoxComponent MinuteHandDeathBox;
	default MinuteHandDeathBox.bGenerateOverlapEvents = false;
	default MinuteHandDeathBox.CollisionProfileName = n"";

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = HourHandBase)
	UHazeAkComponent HazeAkCompHour;

	UPROPERTY(DefaultComponent, Attach = MinuteHandBase)
	UHazeAkComponent HazeAkCompMinute;

	UPROPERTY(Category = "Doppler")
	UAkAudioEvent ClockHandPassbyEventHour;

	UPROPERTY(Category = "Doppler")
	UAkAudioEvent ClockHandPassbyEventMinute;

	UPROPERTY(Category = "Doppler")
	float PassbyApexTime;

	UPROPERTY(Category = "Doppler")
	float PassbyCooldown;

	UPROPERTY()
	float TargetRotationSpeedMinuteHand;
	
	UPROPERTY()
	float TargetRotationSpeedHourHand;

	UPROPERTY()
	bool bRotateHands;

	UPROPERTY()
	float RotationSpeedModifier = 1.f;

	// Spline actors attached to the elevator; adding actors disables generate overlap on all meshes.
	UPROPERTY()
	TArray<AActor> SplineActors;

	FHazeAcceleratedFloat RotationSpeedMinuteHand;
	FHazeAcceleratedFloat RotationSpeedHourHand;
	TArray<AHazePlayerCharacter> MinuteOverlappingPlayers;
	TArray<AHazePlayerCharacter> HourOverlappingPlayers;

	UDopplerEffect ClockHandHourDoppler;
	UDopplerEffect ClockHandMinuteDoppler;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Disable generate overlaps on attached splines
		for (AActor Spline : SplineActors)
		{
			if (Spline == nullptr)
				continue;

			TArray<UStaticMeshComponent> Meshes;
			Spline.GetComponentsByClass(Meshes);

			for (UStaticMeshComponent Mesh : Meshes)
				Mesh.bGenerateOverlapEvents = false;
		}

		if(ClockHandPassbyEventHour != nullptr)
		{
			ClockHandHourDoppler = Cast<UDopplerEffect>(HazeAkCompHour.AddEffect(UDopplerEffect::StaticClass(), bStartEnabled = true));
			ClockHandHourDoppler.SetObjectDopplerValues(false, Observer = EHazeDopplerObserverType::BothPlayers);
			ClockHandHourDoppler.PlayPassbySound(ClockHandPassbyEventHour, PassbyApexTime, PassbyCooldown);
		}
		
		//PassBy on Minute Hand does not work
		if(ClockHandPassbyEventMinute != nullptr)
		{
			ClockHandMinuteDoppler = Cast<UDopplerEffect>(HazeAkCompMinute.AddEffect(UDopplerEffect::StaticClass(), bStartEnabled = true));
			ClockHandMinuteDoppler.SetObjectDopplerValues(false, Observer = EHazeDopplerObserverType::BothPlayers);
			ClockHandMinuteDoppler.PlayPassbySound(ClockHandPassbyEventMinute, PassbyApexTime, PassbyCooldown);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		RotationSpeedMinuteHand.AccelerateTo(TargetRotationSpeedMinuteHand * RotationSpeedModifier, 5.f, DeltaTime);
		RotationSpeedHourHand.AccelerateTo(TargetRotationSpeedHourHand * RotationSpeedModifier, 5.f, DeltaTime);
		
		if (!bRotateHands)
			return;

		MinuteHandBase.AddRelativeRotation(FRotator(0.f, RotationSpeedMinuteHand.Value * DeltaTime, 0.f));
		HourHandBase.AddRelativeRotation(FRotator(0.f, RotationSpeedHourHand.Value * DeltaTime, 0.f));

		for (auto Player : Game::Players)
		{
			if (Player == nullptr || !Player.HasControl())
				continue;

			TracePlayerOverlapComponent(Player, MinuteHandDeathBox, MinuteOverlappingPlayers);
			TracePlayerOverlapComponent(Player, HourHandDeathBox, HourOverlappingPlayers);
		}

		float RotationSpeedMinuteNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-100.f, 100.f), FVector2D(-1.f, 1.f), RotationSpeedMinuteHand.Value); 
		float RotationSpeedHourNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-100.f, 100.f), FVector2D(-1.f, 1.f), RotationSpeedHourHand.Value); 

		HazeAkCompMinute.SetRTPCValue("Rtpc_Clockwork_LowerTower_Platform_ClockElevator_Velocity_Minutes", RotationSpeedMinuteNormalized);
		HazeAkCompHour.SetRTPCValue("Rtpc_Clockwork_LowerTower_Platform_ClockElevator_Velocity_Hours", RotationSpeedHourNormalized);
	}

	UFUNCTION(BlueprintCallable)
	void ResetRotationSpeed()
	{
		RotationSpeedHourHand.Value = 0.f;
		RotationSpeedMinuteHand.Value = 0.f;
	}

	private bool TracePlayerOverlapComponent(AHazePlayerCharacter Player, UPrimitiveComponent Component,
		TArray<AHazePlayerCharacter>& OverlapArray)
	{
		bool bWasOverlapping = OverlapArray.Contains(Player);
		bool bIsOverlapping = Trace::ComponentOverlapComponent(Player.CapsuleComponent, 
			Component,
			Component.WorldLocation,
			Component.ComponentQuat, 
			false);

		if (bIsOverlapping && !bWasOverlapping)
		{
			NetTriggerBeginOverlap(Player, Component);

			if (!OverlapArray.Contains(Player))
				OverlapArray.Add(Player);
		}
		else if (!bIsOverlapping && bWasOverlapping)
		{
			NetTriggerEndOverlap(Player, Component);

			if (OverlapArray.Contains(Player))
				OverlapArray.Remove(Player);
		}

		return bIsOverlapping;
	}

	UFUNCTION(NetFunction)
	private void NetTriggerBeginOverlap(AHazePlayerCharacter Player, UPrimitiveComponent Component)
	{
		Component.TriggerMutualBeginOverlap(Player.CapsuleComponent);
	}

	UFUNCTION(NetFunction)
	private void NetTriggerEndOverlap(AHazePlayerCharacter Player, UPrimitiveComponent Component)
	{
		Component.TriggerMutualEndOverlap(Player.CapsuleComponent);
	}
}