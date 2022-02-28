import Peanuts.Spline.SplineComponent;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Peanuts.Audio.AudioSpline.AudioSpline;

struct CritterAnt
{
	UPROPERTY()
	UStaticMeshComponent MeshComp;

	UPROPERTY()
	float Location;
}

class AAntLine : AAudioSpline
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	// Handle it ourselves instead of using the disablecomp
	default SplineAkComp.bUseAutoDisable = false;
	
    UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;
	default Spline.AutoTangents = true;

    UPROPERTY()
	float SoundDisableDistance = 3000;

    UPROPERTY()
	int AntCount = 10;

    UPROPERTY()
	float AntMoveSpeed = 250;

    UPROPERTY()
	UStaticMesh Mesh;
	
    UPROPERTY()
	UNiagaraSystem DeathEffect;

    UPROPERTY(Category = "zzInternal")
	TArray<CritterAnt> AntPool;

    UPROPERTY(Category = "zzInternal")
	float AntSpacing = 0;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SquashAudioEvent;

	float StartAnimateSpeed = 0;
	float DefaultMoveSpeed = 250;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Super::BeginPlay();
		for (int i = 0; i < ConstructionScriptTempMeshes.Num(); i++)
		{
			if(ConstructionScriptTempMeshes[i] != nullptr)
				ConstructionScriptTempMeshes[i].DestroyComponent(ConstructionScriptTempMeshes[i]);
		}
		AntPool.Empty();
		ConstructionScriptTempMeshes.Empty();
		
		Landed = TArray<bool>();
		LastLanded = TArray<bool>();
		Landed.Add(false);
		Landed.Add(false);
		LastLanded.Add(false);
		LastLanded.Add(false);

		if(Mesh == nullptr)
			return;

		if(AntCount == 0)
			return;
			
		for (int i = 0; i < AntCount; i++)
		{
			float t = (float(i) / float(AntCount - 1.0f)) * Spline.SplineLength;
			auto NewMesh = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent::StaticClass()));
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";
			NewMesh.SetWorldTransform(Spline.GetTransformAtDistanceAlongSpline(t, ESplineCoordinateSpace::World));

			CritterAnt a = CritterAnt();
			a.MeshComp = NewMesh;
			a.Location = t;
			AntPool.Add(a);
			auto mat = NewMesh.CreateDynamicMaterialInstance(0);
			StartAnimateSpeed = mat.GetScalarParameterValue(n"Blend1AnimateSpeed");
			NewMesh.SetScalarParameterValueOnMaterials(n"Blend1AnimateSpeed", StartAnimateSpeed * (AntMoveSpeed / DefaultMoveSpeed));
		}

		AntSpacing = Spline.SplineLength / AntCount;
	}

    UPROPERTY(Category = "zzInternal")
	TArray<UStaticMeshComponent> ConstructionScriptTempMeshes;

	// Do this on construction so the artists can see it.
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		//Super::ConstructionScript();
		if(Mesh == nullptr)
			return;
		
		if(AntCount == 0)
			return;
			
		ConstructionScriptTempMeshes.Empty();
		for (int i = 0; i < AntCount; i++)
		{
			float t = (float(i) / float(AntCount - 1.0f)) * Spline.SplineLength;
			UStaticMeshComponent NewMesh = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent::StaticClass()));
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";
			NewMesh.bIsEditorOnly = true;
			NewMesh.SetWorldTransform(Spline.GetTransformAtDistanceAlongSpline(t, ESplineCoordinateSpace::World));
			ConstructionScriptTempMeshes.Add(NewMesh);
		}
		
		TArray<FVector> a = TArray<FVector>();
		a.SetNumZeroed(Spline.NumberOfSplinePoints);
		SplineComponent.ClearSplinePoints();

		for (int i = 0; i < Spline.NumberOfSplinePoints; i++)
		{
			SplineComponent.AddSplinePoint(Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::Local) + FVector(0, 0, 0), ESplineCoordinateSpace::Local, true);
			SplineComponent.SetRotationAtSplinePoint(i, Spline.GetRotationAtSplinePoint(i, ESplineCoordinateSpace::Local), ESplineCoordinateSpace::Local, true);
			SplineComponent.SetTangentAtSplinePoint(i, Spline.GetTangentAtSplinePoint(i, ESplineCoordinateSpace::Local), ESplineCoordinateSpace::Local, true);
		}
    }

	TArray<bool> Landed;
	TArray<bool> LastLanded;
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if(Mesh == nullptr)
			return;

		if(AntCount == 0)
			return;
		
		if(AntPool.Num() <= 0)
			return;

		const TArray<AHazePlayerCharacter>& GamePlayers = Game::GetPlayers();
		for (int i = 0; i < GamePlayers.Num(); i++)
		{
			AHazePlayerCharacter Player = GamePlayers[i];
			
			auto GroundPoundComponent = UCharacterGroundPoundComponent::Get(Player);
			Landed[i] = false;
			if(GroundPoundComponent != nullptr)
			{
				if(GroundPoundComponent.IsCurrentState(EGroundPoundState::Landing))
				{
					Landed[i] = true;
				}
			}

			if(LastLanded[i] != Landed[i])
			{
				LastLanded[i] = Landed[i];
				if(Landed[i])
				{
					for (int j = 0; j < AntCount; j++) // loop through all the ants and kill the ones nearby
					{
						if(AntPool[j].MeshComp == nullptr)
							continue;
							
						if(AntPool[j].MeshComp.GetWorldLocation().Distance(Player.GetActorLocation()) < 150)
						{
							AntPool[j].MeshComp.DestroyComponent(AntPool[j].MeshComp);

							if(DeathEffect != nullptr)
								Niagara::SpawnSystemAtLocation(DeathEffect, AntPool[j].MeshComp.GetWorldLocation());
							if(SquashAudioEvent != nullptr)
								Player.PlayerHazeAkComp.HazePostEvent(SquashAudioEvent);

							AntPool[j].MeshComp = nullptr;
						}
					}
				}
			}
		}

		for (int i = 0; i < AntCount; i++)
		{
			if(AntPool[i].MeshComp == nullptr)
				continue;

			AntPool[i].MeshComp.SetWorldTransform(Spline.GetTransformAtDistanceAlongSpline(AntPool[i].Location, ESplineCoordinateSpace::World));
			// wrapping around.
			if(AntPool[i].Location > Spline.SplineLength)
			{
				AntPool[i].Location = 0;
			}
			
			// look at all the ants and check if there is enough room in front of us to move.
			bool EnoughRoomToMove = true;
			//for (int j = 0; j < AntCount; j++)
			//{
			//	if(AntPool[j].Location == 0)
			//		continue;
			//
			//	float distance = (AntPool[j].Location - AntPool[i].Location);
			//	
			//	if(distance <= 0)
			//		continue;
			//
			//	if(distance < AntSpacing)
			//	{
			//		EnoughRoomToMove = false;
			//		break;
			//	}
			//}
			//
			//// check if we are blocked by the player.
			bool BlockedByPlayer = false;
			//for(AHazePlayerCharacter Player : Game::GetPlayers())
			//{
			//	if(AntPool[i].MeshComp.GetWorldLocation().Distance(Player.GetActorLocation()) < 100)
			//	{
			//		BlockedByPlayer = true;
			//	}
			//}

			if(!BlockedByPlayer && EnoughRoomToMove)
			{
				AntPool[i].Location += DeltaTime * AntMoveSpeed;
			}
		}
    }
}