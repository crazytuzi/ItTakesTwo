import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Peanuts.Audio.AudioStatics;

class UWaspWeaponSpinningComponent : UPoseableMeshComponent
{
	UHazeAkComponent SawHazeAkComp;
	UWaspBehaviourComponent WaspOwnerBehaviourComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartSpinningEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent IsAttackingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSpinningEvent;
	
	default SetComponentTickEnabled(false);

	UPROPERTY()
	FName SpinBone = n"Blade";

	UPROPERTY()
	float DegreesPerSecond = 3600.f;

	UPROPERTY()
	float StartDuration = 5.f;

	UPROPERTY()
	TArray<EWaspState> SpinStates;
	default SpinStates.Add(EWaspState::Attack);
	default SpinStates.Add(EWaspState::Telegraphing);

	UPROPERTY()
	float TelegraphDelay = 2.f;

	UPROPERTY()
	float StopDuration = 5.f;

	bool bSpinning = false;
	FHazeAcceleratedFloat SpinSpeed;
	float StopMinTime = 0.f;
	EWaspState LastState; 

	UPROPERTY(NotVisible, BlueprintReadOnly)
	TArray<UNiagaraComponent> EffectsComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<USceneComponent> Children;
		GetChildrenComponents(true, Children);
		for (USceneComponent Child : Children)
		{
			UNiagaraComponent EffectsChild = Cast<UNiagaraComponent>(Child);
			if (EffectsChild != nullptr)
				EffectsComponents.Add(EffectsChild);
		}

		SawHazeAkComp = UHazeAkComponent::GetOrCreate(GetOwner());
		WaspOwnerBehaviourComp = UWaspBehaviourComponent::Get(GetOwner());
	}

	UFUNCTION()
	void StartSpinning()
	{
		if (!bSpinning)
			OnStartSpinning();

		bSpinning = true;
		SetComponentTickEnabled(true);
		SawHazeAkComp.HazePostEvent(StartSpinningEvent);
	}

	UFUNCTION()
	void StopSpinning()
	{
		if (bSpinning)
			OnSlowingDown();

		bSpinning = false;
		StopMinTime = Time::GetGameTimeSeconds() + StopDuration;
		SawHazeAkComp.HazePostEvent(StopSpinningEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bSpinning)
		{
			SpinSpeed.AccelerateTo(DegreesPerSecond, StartDuration, DeltaTime);

			if(WaspOwnerBehaviourComp.State == EWaspState::Attack && LastState != EWaspState::Attack)
			{
				SawHazeAkComp.SetRTPCValue("Rtpc_Gadgets_WaspSawBlade_IsAttacking", 1.f);
				SawHazeAkComp.HazePostEvent(IsAttackingEvent);
				LastState = EWaspState::Attack;
			}
			else if(WaspOwnerBehaviourComp.State != EWaspState::Attack && LastState == EWaspState::Attack)
			{
				SawHazeAkComp.SetRTPCValue("Rtpc_Gadgets_WaspSawBlade_IsAttacking", 0.f);
				LastState = EWaspState::None;
			}
		}
		else
		{
			// Stopping spin
			SpinSpeed.SpringTo(0.f, 10.f / FMath::Max(0.01f, StopDuration), 0.7f, DeltaTime);
			if ((Time::GetGameTimeSeconds() > StopMinTime) && FMath::IsNearlyZero(SpinSpeed.Value, 0.1f))
			{
				SetComponentTickEnabled(false);
				OnStoppedSpinning();
			}
		}

		FRotator SpinRot = GetBoneRotationByName(SpinBone, EBoneSpaces::ComponentSpace);
		SpinRot.Roll -= SpinSpeed.Value * DeltaTime;		
		SetBoneRotationByName(SpinBone, SpinRot, EBoneSpaces::ComponentSpace);
	}

	// 0 if stopped, 1 if at full speed
	UFUNCTION(BlueprintPure)
	float GetSpinSpeedFraction()
	{
		if (FMath::IsNearlyZero(DegreesPerSecond))
			return 0.f;

		return FMath::Abs(SpinSpeed.Value / DegreesPerSecond);
	}

	UFUNCTION(BlueprintEvent)
	void OnStartSpinning(){}

	UFUNCTION(BlueprintEvent)
	void OnSlowingDown(){}

	UFUNCTION(BlueprintEvent)
	void OnStoppedSpinning(){}
}