event void FOnStartVacuuming(USceneComponent NozzleComponent);
event void FOnEndVacuuming();
event void FOnTickVacuuming(FVector VacuumDirection);
event void FOnEnterVacuum(USceneComponent NozzleComponent);
event void FOnExitVacuum();
event void FOnHitByWindBurst();
event void FOnTickInsideVacuum(float Distance);

class UVacuumableComponent : UActorComponent
{
	UPROPERTY()
	FOnStartVacuuming OnStartVacuuming;

    UPROPERTY()
    FOnEndVacuuming OnEndVacuuming;

    UPROPERTY()
    FOnTickVacuuming OnTickVacuuming;

    UPROPERTY()
    FOnEnterVacuum OnEnterVacuum;

    UPROPERTY()
    FOnExitVacuum OnExitVacuum;

	UPROPERTY()
	FOnTickInsideVacuum OnTickInsideVacuum;

    UPROPERTY()
    bool bAffectedByVacuum = true;
	bool bCanEnterVacuum = true;
	
	UPROPERTY()
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartObjectInsideTubeEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopObjectInsideTubeEvent;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeAkComp = UHazeAkComponent::GetOrCreate(Owner);		
	}

    void StartVacuuming(USceneComponent Nozzle)
    {
        OnStartVacuuming.Broadcast(Nozzle);
    }

    void EndVacuuming()
    {
        OnEndVacuuming.Broadcast();
    }

    void TickVacuuming(FVector VacuumDirection)
    {
        OnTickVacuuming.Broadcast(VacuumDirection);
    }

    void EnterVacuum(USceneComponent Nozzle)
    {
        OnEnterVacuum.Broadcast(Nozzle);
		
		HazeAkComp.HazePostEvent(StartObjectInsideTubeEvent);
		
    }

	void TickInsideVacuum(float Distance)
	{
		OnTickInsideVacuum.Broadcast(Distance);
		
		if (HazeAkComp != nullptr)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_InsideHoseDistance_Objects", Distance);
			//Print("DistinsideTube"+ Distance);
		}
	}

    void ExitVacuum()
    {
        OnExitVacuum.Broadcast();
		HazeAkComp.HazePostEvent(StopObjectInsideTubeEvent);
    }
}