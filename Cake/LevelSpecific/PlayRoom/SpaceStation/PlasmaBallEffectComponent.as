import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

class UPlasmaBallEffectComponent : USceneComponent
{
	UPROPERTY()
	UNiagaraSystem BeamSystem;

	UNiagaraComponent MayLeftBeamComp;
	UNiagaraComponent MayRightBeamComp;

	UNiagaraComponent CodyLeftBeamComp;
	UNiagaraComponent CodyRightBeamComp;

	bool bTrackingMayFeet = false;
	bool bTrackingCodyFeet = false;
	bool bTrackingCodyHands = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnBeamComp(MayLeftBeamComp);
		SpawnBeamComp(MayRightBeamComp);
		SpawnBeamComp(CodyLeftBeamComp);
		SpawnBeamComp(CodyRightBeamComp);

		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnBall");
		BindOnDownImpactedByPlayer(HazeOwner, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeaveBall");
		BindOnDownImpactEndedByPlayer(HazeOwner, NoImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnBall(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (Player == Game::GetMay())
			SetMayFootTracking(true);
		else
			SetCodyFootTracking(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeaveBall(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetMay())
			SetMayFootTracking(false);
		else
			SetCodyFootTracking(false);
	}

	void SetMayFootTracking(bool bTrack)
	{
		bTrackingMayFeet = bTrack;
		SetBeamActiveForPlayer(Game::GetMay(), bTrack);
	}

	void SetCodyFootTracking(bool bTrack)
	{
		bTrackingCodyFeet = bTrack;
		SetBeamActiveForPlayer(Game::GetCody(), bTrack);
	}

	void SetCodyHandTracking(bool bTrack)
	{
		bTrackingCodyHands = bTrack;
		SetBeamActiveForPlayer(Game::GetCody(), bTrack);
	}

	void SetBeamActiveForPlayer(AHazePlayerCharacter Player, bool bActive)
	{
		if (Player.IsMay())
		{
			if (bActive)
			{
				MayLeftBeamComp.Activate(true);
				MayRightBeamComp.Activate(true);
			}
			else
			{
				MayLeftBeamComp.Deactivate();
				MayRightBeamComp.Deactivate();
			}
		}
		else
		{
			if (bActive)
			{
				CodyLeftBeamComp.Activate(true);
				CodyRightBeamComp.Activate(true);
			}
			else
			{
				CodyLeftBeamComp.Deactivate();
				CodyRightBeamComp.Deactivate();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bTrackingMayFeet)
		{
			MayLeftBeamComp.SetWorldRotation(GetDesiredEffectRotation(Game::GetMay(), n"LeftFoot"));
			MayRightBeamComp.SetWorldRotation(GetDesiredEffectRotation(Game::GetMay(), n"RightFoot"));
		}

		if (bTrackingCodyFeet || bTrackingCodyHands)
		{
			FName CodyLeftSocket = bTrackingCodyHands ? n"LeftHand" : n"LeftFoot";
			CodyLeftBeamComp.SetWorldRotation(GetDesiredEffectRotation(Game::GetCody(), CodyLeftSocket));

			FName CodyRightSocket = bTrackingCodyHands ? n"RightHand" : n"RightFoot";
			CodyRightBeamComp.SetWorldRotation(GetDesiredEffectRotation(Game::GetCody(), CodyRightSocket));
		}
	}

	FRotator GetDesiredEffectRotation(AHazePlayerCharacter Player, FName Socket)
	{
		FVector Dir = Player.Mesh.GetSocketLocation(Socket) - WorldLocation;
		Dir.Normalize();

		FRotator Rot = Math::MakeRotFromZ(Dir);
		return Rot;
	}

	void SpawnBeamComp(UNiagaraComponent& Comp)
	{
		Comp = Niagara::SpawnSystemAttached(BeamSystem, this, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false, false);
	}
}