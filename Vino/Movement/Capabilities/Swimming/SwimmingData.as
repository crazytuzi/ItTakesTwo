class USwimmingAudioData : UDataAsset
{
	UPROPERTY(Category = General)
	UAkAudioEvent PlayerSubmerged;

	UPROPERTY(Category = General)
	UAkAudioEvent PlayerStartUnderwaterVOEvent;
	
	UPROPERTY(Category = General)
	UAkAudioEvent PlayerStopUnderwaterVOEvent;

	UPROPERTY(Category = General)
	UAkAudioEvent PlayerSurfaced;

	UPROPERTY(Category = Splash)	
	UAkAudioEvent PlayerSplashNormal;

	UPROPERTY(Category = Splash)	
	UAkAudioEvent PlayerSplashBreachApex;

	UPROPERTY(Category = Surface)
	UAkAudioEvent SurfaceEnteredFromAir;

	UPROPERTY(Category = Surface)
	UAkAudioEvent SurfaceEnteredFromWater;

	UPROPERTY(Category = Surface)
	UAkAudioEvent SurfaceExitJump;

	UPROPERTY(Category = Surface)
	UAkAudioEvent SurfaceExitDive;

	UPROPERTY(Category = Surface)
	UAkAudioEvent SurfaceStartedMoving;

	UPROPERTY(Category = Surface)
	UAkAudioEvent SurfaceStoppedMoving;

	UPROPERTY(Category = Submerged)	
	UAkAudioEvent SubmergedEnteredNormal;

	UPROPERTY(Category = Submerged)	
	UAkAudioEvent SubmergedEnteredFast;

	UPROPERTY(Category = Submerged)
	UAkAudioEvent SubmergedEnteredCruise;

	UPROPERTY(Category = Submerged)
	UAkAudioEvent SubmergedDash;

	UPROPERTY(Category = Submerged)
	UAkAudioEvent SubmergedStartedMoving;

	UPROPERTY(Category = Submerged)
	UAkAudioEvent SubmergedStoppedMoving;

	UPROPERTY(Category = Submerged)
	UAkAudioEvent SubmergedBreach;
	
	// UPROPERTY(Category = Submerged)
	// UAkAudioEvent SubmergedBreachLanding;


	UPROPERTY(Category = Vortex)
	UAkAudioEvent VortexEnteredFromWater;

	UPROPERTY(Category = Vortex)
	UAkAudioEvent VortexEnteredFromAir;

	UPROPERTY(Category = Vortex)
	UAkAudioEvent VortexDash;

	UPROPERTY(Category = Vortex)
	UAkAudioEvent VortexStartedMovingUp;

	UPROPERTY(Category = Vortex)
	UAkAudioEvent VortexStartedMovingDown;

	UPROPERTY(Category = Vortex)
	UAkAudioEvent VortexStoppedMoving;

	UPROPERTY(Category = Vortex)
	UAkAudioEvent VortexStartedTurning;

	UPROPERTY(Category = Vortex)
	UAkAudioEvent VortexStoppedTurning;

	UPROPERTY(Category = Vortex)
	UAkAudioEvent VortexExited;


	UPROPERTY(Category = Stream)
	UAkAudioEvent StreamEnter;

	UPROPERTY(Category = Stream)
	UAkAudioEvent StreamEnterSoft;

	UPROPERTY(Category = Stream)
	UAkAudioEvent StreamExit;

	UPROPERTY(Category = VO)
	UAkAuxBus UnderwaterVOReverbAux;
}

class USwimmingEffectsData : UDataAsset
{
	
}