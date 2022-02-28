import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Peanuts.Aiming.AutoAimTarget;

event void FOnMainFountainWhippableCompleted();

class AFrogPondMainFountainWhippable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WhippableRotationBase;
	default WhippableRotationBase.RelativeLocation = FVector(0.f,0.f, 400.f);
	default WhippableRotationBase.RelativeRotation = FRotator(0.f, 90.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = WhippableRotationBase)
	UStaticMeshComponent WhippableMesh;

	UPROPERTY(DefaultComponent, Attach = WhippableMesh)
	UBoxComponent WhipTrigger;

	UPROPERTY(DefaultComponent, Attach = WhipTrigger)
	UVineImpactComponent VineImpactComp;

	UPROPERTY(DefaultComponent, Attach = VineImpactComp)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 10000.f;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent VineConnectedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopAudioEvent;

	UPROPERTY(EditDefaultsOnly ,Category = "Setup")
	FHazeTimeLike RotationTimelike;

	UPROPERTY(Category = "Settings")
	float YawRotationToAdd = 90.f;

	UPROPERTY()
	FOnMainFountainWhippableCompleted MainFountainActivated;

	float StartYaw = 0.f;
	bool Completed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotationTimelike.BindUpdate(this, n"OnRotationUpdate");
		RotationTimelike.BindFinished(this, n"OnRotationFinished");

		VineImpactComp.OnVineConnected.AddUFunction(this, n"WhipConnected");
		VineImpactComp.OnVineDisconnected.AddUFunction(this ,n"WhipReleased");

		StartYaw = WhippableRotationBase.RelativeRotation.Yaw;
	}

	UFUNCTION()
	void SetCompleted()
	{
		FRotator FinalRotation = FRotator(WhippableRotationBase.RelativeRotation.Pitch, StartYaw + YawRotationToAdd, WhippableRotationBase.RelativeRotation.Roll);
		WhippableRotationBase.SetRelativeRotation(FinalRotation);
		VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		AutoAimTargetComp.SetAutoAimEnabled(false);
	}

	UFUNCTION()
	void WhipConnected()
	{
		if(!Completed)
		{
			RotationTimelike.Play();
			HazeAkComp.HazePostEvent(VineConnectedAudioEvent);
		}
			
	}

	UFUNCTION()
	void WhipReleased()
	{
		if(!Completed)
		{
			RotationTimelike.Reverse();
		}
			
	}

	UFUNCTION()
	void OnRotationUpdate(float Value)
	{
		float NewYaw = FMath::Lerp(StartYaw, StartYaw + YawRotationToAdd, Value);
		FRotator NewRotation = FRotator(WhippableRotationBase.RelativeRotation.Pitch, NewYaw, WhippableRotationBase.RelativeRotation.Roll);
		WhippableRotationBase.SetRelativeRotation(NewRotation);
	}

	UFUNCTION()
	void OnRotationFinished()
	{
		if(!RotationTimelike.IsReversed() && HasControl())
		{
/* 			Completed = true;
			VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			AutoAimTargetComp.SetAutoAimEnabled(false);
			MainFountainActivated.Broadcast(); */

			WhippableCompleted();
		}

		if(RotationTimelike.IsReversed())
		{
			HazeAkComp.HazePostEvent(StopAudioEvent);
		}
	}

	UFUNCTION(NetFunction)
	void WhippableCompleted()
	{
		Completed = true;
		VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		AutoAimTargetComp.SetAutoAimEnabled(false);
		MainFountainActivated.Broadcast();
	}
}