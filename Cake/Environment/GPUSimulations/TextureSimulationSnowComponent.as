import Cake.Environment.GPUSimulations.TextureSimulationComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Audio.Footsteps.AnimNotify_Footstep;

// one of these per player for snow.
class UTextureSimulationSnowComponent : UTextureSimulationComponent
{
	UPROPERTY(Category = "Input")
	bool TestTestTest;

	UPROPERTY(Category = "Input")
	float WorldWidth = 4000;

	UPROPERTY(Category = "Input")
	float WorldHeight = 4000;

	UPROPERTY(Category = "Input")
	bool IsMay = true;

	UPROPERTY(Category = "Input")
	UNiagaraSystem FootstepEffect;

	UPROPERTY(Category = "System")
	FVector LastLocation;

	UPROPERTY(Category = "System")
	FVector LastLocationSnapped;

	UPROPERTY(Category = "System")
	FVector OtherLastLocation;

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		UTextureSimulationComponent::BeginPlay();

		if(Owner == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);

		if(Player == nullptr)
			return;

		Player.BindAnimNotifyDelegate(UAnimNotify_Footstep::StaticClass(), FHazeAnimNotifyDelegate(this, n"FootstepHappened"));
	}


	UPROPERTY(Category = "System")
	float MissingDeltaX = 0;

	UPROPERTY(Category = "System")
	float MissingDeltaY = 0;

	float SnapTo512(float a)
	{
		return FMath::RoundToFloat(a * 512.0f) / 512;
	}

	FVector SnapTo512(FVector a)
	{
		return FVector(SnapTo512(a.X), SnapTo512(a.Y), SnapTo512(a.Z));
	}

	UFUNCTION()
	void FootstepHappened(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		PaintStrength = 0.5f;
		WorldPaintLocation = Owner.GetActorLocation();
		if(FootstepEffect != nullptr)
			Niagara::SpawnSystemAtLocation(FootstepEffect, WorldPaintLocation, Owner.GetActorRotation());
	}

	float PaintStrength = 0.0f;
	bool Landing = false;
	bool LastLanding = false;
	float Pound = 0.0f;

	bool UpdatePosition = false;	
	
	FVector WorldPaintLocation;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// TODO (MW) Don't filter on detail mode here, filter on shader quality instead. This will lead to unpredictable behaviour if you set detail mode to low but shader quality to high.
		if(Game::DetailModeLow)
			return;

		FName TransformName = IsMay ? n"LandscapeSimulationTransformA" : n"LandscapeSimulationTransformB";
		float PlayerNumber = IsMay ? 0.0f : 1.0f;
		
		if(Owner == nullptr)
			return;

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Owner);

		if(MoveComp == nullptr)
			return;

		if(!MoveComp.IsGrounded()) // is jumping
		{
			PaintStrength = 0.0f;
		}

		FVector DeltaLocation = LastLocation - Owner.GetActorLocation();
		LastLocation = Owner.GetActorLocation();

		FVector DeltaLocaitonSnapped = LastLocationSnapped - SnapTo512(Owner.GetActorLocation() / WorldWidth);
		LastLocationSnapped  = SnapTo512(Owner.GetActorLocation() / WorldWidth);

		float Random = FMath::Frac(LastLocation.X + LastLocation.Y + LastLocation.Z);

		if(DeltaLocation.SizeSquared() <= 0)
		{
			PaintStrength = 0.0f;
		}
		
		Landing = false;
		auto GroundPoundComponent = UCharacterGroundPoundComponent::Get(Owner);
		if(GroundPoundComponent != nullptr)
		{
			if(GroundPoundComponent.IsCurrentState(EGroundPoundState::Landing))
			{
				Landing = true;
				WorldPaintLocation = Owner.GetActorLocation();
			}
		}
		if(Landing != LastLanding)
		{
			if(Landing) // Landed
				Pound = 0.2f;

			LastLanding = Landing;
		}
		
		Pound -= DeltaTime;
		if(Pound < 0)
			Pound = 0;
		
		//WorldPaintLocation = FVector(-46027, 31081, 346);
		FVector CenterPoint = ((WorldPaintLocation / WorldWidth) - LastLocationSnapped);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"CenterpointX", CenterPoint.X + 0.5f);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"CenterpointY", CenterPoint.Y + 0.5f);

		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"DeltaPositionX", DeltaLocaitonSnapped.X);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"DeltaPositionY", DeltaLocaitonSnapped.Y);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"PaintStrength", PaintStrength * 0.25f);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Player", PlayerNumber);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"PlaneScale", WorldWidth);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Random", Random);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Pound", Pound * 2.0f);
		UpdateSimulationMaterialDynamic.SetScalarParameterValue(n"Scale", 0.02);
		
		// Set Plane transform for material to read
		Material::SetVectorParameterValue(WorldShaderParameters, TransformName,
		FLinearColor((LastLocationSnapped.X * WorldWidth) - WorldWidth  * 0.5f,
	    			 (LastLocationSnapped.Y * WorldWidth) - WorldHeight * 0.5f, 
					 WorldWidth, WorldHeight));

		UTextureSimulationComponent::Tick(DeltaTime);
		
		PaintStrength -= DeltaTime;
		
		if(PaintStrength < 0)
			PaintStrength = 0;
	}
}
