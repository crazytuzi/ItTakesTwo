import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Vino.Movement.Swinging.SwingPoint;
import Peanuts.Audio.AudioStatics;
import Peanuts.Aiming.AutoAimTarget;

event void FOnWhippableTreeBranchWhippedSignature();

class AWhippableTreeBranch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseArmMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent SwingArmMesh;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USphereComponent VineTrigger;

	UPROPERTY(DefaultComponent, Attach = VineTrigger)
	UVineImpactComponent VineComp;

	UPROPERTY(DefaultComponent, Attach = VineComp)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent, Attach = VineComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Settings")
	float PitchTarget = -15.f;

	UPROPERTY(Category = "Settings")
	float YawTarget = -5.f;

	UPROPERTY(Category = "Settings")
	float MinimumSelectDistance = 300.f;

	UPROPERTY(Category = "Settings")
	float MinimumTargetDistance = 500.f;

	UPROPERTY(Category = "Settings")
	float MinimumVisibleDistance = 500.f;

	FVector LastVelocity;
	float LastVeloRtpcValue = 0.f;

	float InitialVisibleDistance = 0.f;
	float InitialSelectDistance = 0.f;
	float InitialTargetDistance = 0.f;

	FRotator DefaultRotation;
	FRotator TargetRotation;

	bool VineIsConnected = false;
	bool HasBroadcastWhippedEvent = false;

	UPROPERTY(Category = "Settings")
	FHazeTimeLike WhipConnectedTimelike;

	UPROPERTY(Category = "Settings")
	ASwingPoint SwingPoint;

	UPROPERTY()
	FOnWhippableTreeBranchWhippedSignature WhippedEvent;

	UFUNCTION(BlueprintEvent)
	void BP_BranchStartMove()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_BranchStopMove()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_BranchVineConnected()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_BranchVineDisconnected()
	{}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VineComp.OnVineConnected.AddUFunction(this, n"VineConnected");
		VineComp.OnVineDisconnected.AddUFunction(this, n"VineDisconnected");

		WhipConnectedTimelike.BindUpdate(this, n"ConnectedUpdate");
		WhipConnectedTimelike.BindFinished(this, n"ConnectedFinished");

		if(SwingPoint != nullptr)
		{
			InitialSelectDistance = SwingPoint.SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Selectable);
			SwingPoint.SwingPointComponent.InitializeDistance(EHazeActivationPointDistanceType::Selectable, MinimumSelectDistance);

			InitialTargetDistance = SwingPoint.SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Targetable);
			SwingPoint.SwingPointComponent.InitializeDistance(EHazeActivationPointDistanceType::Targetable, MinimumTargetDistance);
		}

		DefaultRotation = Root.RelativeRotation;
		TargetRotation = FRotator(DefaultRotation.Pitch + PitchTarget, DefaultRotation.Yaw + YawTarget, DefaultRotation.Roll);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//Audio
		FVector CurrVelo = VineComp.GetWorldLocation();
		float VeloDelta = (CurrVelo - LastVelocity).Size();
		LastVelocity = CurrVelo;

		float NormalizedVelo = HazeAudio::NormalizeRTPC01(VeloDelta, 0.f, 18.f);
		
		if(NormalizedVelo != LastVeloRtpcValue)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Garden_VegetablePatch_Interactable_WhippableTreeBranch_Velocity", NormalizedVelo);
			LastVeloRtpcValue = NormalizedVelo;
		}

		if(NormalizedVelo <= 0)
			BP_BranchStopMove();
		
		if(NormalizedVelo > 0)
			BP_BranchStartMove();
	}

	UFUNCTION()
	void VineConnected()
	{
		VineIsConnected = true;
		WhipConnectedTimelike.Play();

		BP_BranchVineConnected();

		if(!HasBroadcastWhippedEvent)
		{
			WhippedEvent.Broadcast();
			HasBroadcastWhippedEvent = true;
		}
	}

	UFUNCTION()
	void VineDisconnected()
	{
		VineIsConnected = false;
		WhipConnectedTimelike.Reverse();
		BP_BranchVineDisconnected();
	}

	UFUNCTION()
	void ConnectedUpdate(float Value)
	{
		float NewPitch = FMath::Lerp(DefaultRotation.Pitch, TargetRotation.Pitch, Value);
		float NewYaw = FMath::Lerp(DefaultRotation.Yaw, TargetRotation.Yaw, Value);
		FRotator NewRotation = FRotator(NewPitch, NewYaw, TargetRotation.Roll);
		Root.SetRelativeRotation(NewRotation);

		if(SwingPoint != nullptr)
		{
			if(!WhipConnectedTimelike.IsReversed())
			{
				float NewSelectDistance = FMath::Lerp(SwingPoint.SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Selectable), InitialSelectDistance, Value);
				SwingPoint.SwingPointComponent.InitializeDistance(EHazeActivationPointDistanceType::Selectable, NewSelectDistance);

				float NewTargetDistance = FMath::Lerp(SwingPoint.SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Targetable), InitialTargetDistance, Value);
				SwingPoint.SwingPointComponent.InitializeDistance(EHazeActivationPointDistanceType::Targetable, NewTargetDistance);
			}
			else
			{
				float NewSelectDistance = FMath::Lerp(SwingPoint.SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Selectable), MinimumSelectDistance, FMath::Abs(Value - 1));
				SwingPoint.SwingPointComponent.InitializeDistance(EHazeActivationPointDistanceType::Selectable, NewSelectDistance);

				float NewTargetDistance = FMath::Lerp(SwingPoint.SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Targetable), MinimumTargetDistance, FMath::Abs(Value - 1));
				SwingPoint.SwingPointComponent.InitializeDistance(EHazeActivationPointDistanceType::Targetable, NewTargetDistance);
			}
		}
	}

	UFUNCTION()
	void ConnectedFinished()
	{	

	}
}