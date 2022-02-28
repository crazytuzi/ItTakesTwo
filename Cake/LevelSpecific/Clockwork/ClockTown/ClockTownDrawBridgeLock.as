import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.ClockTown.ClockTownDrawBridge;
import Cake.LevelSpecific.Clockwork.VOBanks.ClockworkOutsideVOBank;

event void FClockTownDrawBridgeLockEvent();

UCLASS(Abstract)
class AClockTownDrawBridgeLock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LockRoot;

	UPROPERTY(DefaultComponent, Attach = LockRoot)
	UStaticMeshComponent LeftClaw;

	UPROPERTY(DefaultComponent, Attach = LockRoot)
	UStaticMeshComponent RightClaw;

	UPROPERTY(DefaultComponent, Attach = LockRoot)
	UTimeControlActorComponent TimeControlComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY()
	TArray<AClockTownDrawBridge> Bridges;

	UPROPERTY()
	FClockTownDrawBridgeEvent OnBridgePermanentlyLocked;

	bool bPermanentlyLocked = false;

	bool bLocked = false;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UPROPERTY(EditDefaultsOnly)
	UClockworkOutsideVOBank VOBank;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		LeftClaw.SetCullDistance(Editor::GetDefaultCullingDistance(LeftClaw) * CullDistanceMultiplier);
		RightClaw.SetCullDistance(Editor::GetDefaultCullingDistance(RightClaw) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeControlComp.TimeIsChangingEvent.AddUFunction(this, n"TimeIsChanging");
		TimeControlComp.StartedProgressingTime.AddUFunction(this, n"StartedProgress");
		TimeControlComp.TimeFullyReversedEvent.AddUFunction(this, n"FullyReversed");
		TimeControlComp.CodyStoppedInteractionEvent.AddUFunction(this, n"StartedProgress");

		LeftClaw.SetRelativeRotation(FRotator(0.f, 0.f, 30.f));
		RightClaw.SetRelativeRotation(FRotator(0.f, 180.f, 30.f));
	}

	UFUNCTION()
	void FullyReversed()
	{
		bLocked = true;

		bool bBothBridgesLocked = true;

		for (AClockTownDrawBridge CurBridge : Bridges)
		{
			CurBridge.bBlocked = true;

			if (CurBridge.bLowered)
			{
				CurBridge.LockBridge();
			}
			else
			{
				bBothBridgesLocked = false;
			}
		}

		if (bBothBridgesLocked)
		{
			PermanentlyLock();
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBClockworkOutsideBridgeSuccess");
		}
	}

	UFUNCTION()
	void StartedProgress()
	{
		bLocked = false;

		for (AClockTownDrawBridge CurBridge : Bridges)
		{
			CurBridge.bBlocked = false;
			if (CurBridge.bLowered)
			{
				CurBridge.UnlockBridge();
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void TimeIsChanging(float PointInTime)
	{
		if (!TimeControlComp.bCanBeTimeControlled)
			return;

		float CurRot = FMath::Lerp(30.f, 0.f, PointInTime);
		LeftClaw.SetRelativeRotation(FRotator(0.f, 0.f, CurRot));
		RightClaw.SetRelativeRotation(FRotator(0.f, 180.f, CurRot));
	}

	UFUNCTION()
	void PermanentlyLock()
	{
		if (bPermanentlyLocked)
			return;

		bPermanentlyLocked = true;
		TimeControlComp.DisableTimeControl(this);
		TimeControlComp.StopAllConstants();

		for (AClockTownDrawBridge CurBridge : Bridges)
		{
			CurBridge.PermanentlyLock();
		}

		OnBridgePermanentlyLocked.Broadcast();
	}
}