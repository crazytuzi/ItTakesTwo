struct FTemporaryCollisionIgnore
{
	float Timer = 0.f;
	UPrimitiveComponent Component;
	AActor Actor;
};

class UCollisionIgnoreManagerComponent : UActorComponent
{
	UHazeBaseMovementComponent MoveComp;
	TArray<FTemporaryCollisionIgnore> TemporaryCollisionIgnores;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UHazeBaseMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = 0, Count = TemporaryCollisionIgnores.Num(); i < Count; ++i)
		{
			auto& Ignore = TemporaryCollisionIgnores[i];
			Ignore.Timer -= DeltaTime;

			if (Ignore.Timer <= 0.f)
			{
				if (Ignore.Component != nullptr)
					MoveComp.StopIgnoringComponent(Ignore.Component);
				if (Ignore.Actor != nullptr)
					MoveComp.StopIgnoringActor(Ignore.Actor);
				TemporaryCollisionIgnores.RemoveAt(i);
				--i; --Count;
			}
		}

		if (TemporaryCollisionIgnores.Num() == 0)
			SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for (auto Ignore : TemporaryCollisionIgnores)
		{
			if (Ignore.Component != nullptr)
				MoveComp.StopIgnoringComponent(Ignore.Component);
			if (Ignore.Actor != nullptr)
				MoveComp.StopIgnoringActor(Ignore.Actor);
		}
	}

	void TemporarilyIgnoreComponentCollision(UPrimitiveComponent Component, float Duration)
	{
		MoveComp.StartIgnoringComponent(Component);

		FTemporaryCollisionIgnore Ignore;
		Ignore.Timer = Duration;
		Ignore.Component = Component;
		TemporaryCollisionIgnores.Add(Ignore);

		SetComponentTickEnabled(true);
	}

	void TemporarilyIgnoreActorCollision(AActor Actor, float Duration)
	{
		MoveComp.StartIgnoringActor(Actor);

		FTemporaryCollisionIgnore Ignore;
		Ignore.Timer = Duration;
		Ignore.Actor = Actor;
		TemporaryCollisionIgnores.Add(Ignore);

		SetComponentTickEnabled(true);
	}
}