import Cake.LevelSpecific.Tree.Escape.EscapeManager;

event void FOnBeginOverlapFlyingMachineSignature(AFlyingMachine FlyingMachine);
event void FOnEndOverlapFlyingMachineSignature(AFlyingMachine FlyingMachine);

class UFlyingMachineTriggerVisualizerComponent : UActorComponent { }
class UFlyingMachineTriggerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFlyingMachineTriggerVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		AFlyingMachineTrigger Trigger = Cast<AFlyingMachineTrigger>(Component.Owner);

		if (Trigger == nullptr)
			return;

		DrawWireSphere(Trigger.ActorLocation, Trigger.NearDistance, FLinearColor::Green, 5.f);
		DrawWireSphere(Trigger.ActorLocation, Trigger.FarDistance, FLinearColor::Red, 10.f);
	}
}

class AFlyingMachineTrigger : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"Trigger";

	UPROPERTY(DefaultComponent)
	UFlyingMachineTriggerVisualizerComponent Visualizer;

	// Distance at which we don't check overlaps at all.
    UPROPERTY()
    float FarDistance = 16000.f;

	// Distance at which we check overlaps every frame.
    UPROPERTY()
    float NearDistance = 5000.f;

	// Highest tickrate allowed, lowest is always 0.f.
    UPROPERTY()
    float MaxTickSeconds = 1.f;

	UPROPERTY(Category = "Flying Machine Trigger")
	FOnBeginOverlapFlyingMachineSignature OnBeginOverlapFlyingMachine;
	UPROPERTY(Category = "Flying Machine Trigger")
	FOnEndOverlapFlyingMachineSignature OnEndOverlapFlyingMachine;

	AFlyingMachine Machine = nullptr;
	bool bIsOverlapping = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto EscapeManager = GetEscapeManager();

		if (EscapeManager != nullptr)
			Machine = EscapeManager.TargetMachine;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if (Machine == nullptr)
			return;
			
		float DistanceSqr = (Machine.ActorLocation - ActorLocation).SizeSquared();
		float FarDistanceSqr = FMath::Square(FarDistance);
		float NearDistanceSqr = FMath::Square(NearDistance);

		if (DistanceSqr <= NearDistanceSqr)
		{
			SetActorTickInterval(0.f);
		}
		else
		{
			float Alpha = FMath::Clamp(DistanceSqr / (FarDistanceSqr - NearDistanceSqr), 0.f, 1.f);
			float TickInterval = FMath::Lerp(0.f, MaxTickSeconds, Alpha);
			SetActorTickInterval(TickInterval);
		}

		if (!HasControl() || DistanceSqr >= FarDistanceSqr)
			return;

		bool bWasOverlapping = bIsOverlapping;
		bIsOverlapping = Trace::ComponentOverlapComponent(
			Machine.Mesh,
			Collision,
			Collision.WorldLocation,
			Collision.ComponentQuat,
			bTraceComplex = false);

		if (bIsOverlapping && !bWasOverlapping)
			NetBeginOverlap();

		if (!bIsOverlapping && bWasOverlapping)
			NetEndOverlap();
	}

	UFUNCTION(NetFunction)
	private void NetBeginOverlap()
	{
		OnBeginOverlapFlyingMachine.Broadcast(Machine);
	}

	UFUNCTION(NetFunction)
	private void NetEndOverlap()
	{
		OnEndOverlapFlyingMachine.Broadcast(Machine);
	}
}