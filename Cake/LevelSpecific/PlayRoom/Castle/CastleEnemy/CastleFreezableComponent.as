event void FFreezableSignature(AHazeActor ResponsibleFreezer);

class UCastleFreezableComponent : UActorComponent
{
	UPROPERTY()
	FFreezableSignature OnFreeze;

	UFUNCTION()
	void HitFreezableActor(AHazeActor ResponsibleFreezer)
	{
		if ((ResponsibleFreezer == nullptr && HasControl()) || ResponsibleFreezer.HasControl())
		{
			NetFreeze(ResponsibleFreezer);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetFreeze(AHazeActor ResponsibleFreezer)
	{
		OnFreeze.Broadcast(ResponsibleFreezer);
	}
}