import Vino.StickControlledLever.StickControlledLever;
import Peanuts.Audio.AudioStatics;

class ACircusStickControllerLever : AStickControlledLever
{
	UPROPERTY(DefaultComponent)
	UHazeAkComponent AKComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartRotatingEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopRotatingEvent;

	UFUNCTION()
	void FireStartRotatingEvent()
	{
		AKComp.HazePostEvent(StartRotatingEvent);
	}

	UFUNCTION()
	void FireStopRotatingEvent()
	{
		AKComp.HazePostEvent(StopRotatingEvent);
	}

	UFUNCTION()
	void SetStickRotationVelocityNormalized(float Velocity)
	{
		// AKComp.SetRTPCValue(HazeAudio::RTPC::CircusStickControllerStickVelocity, Velocity, 0);
	}

	UFUNCTION()
	void SetRotationSpeedNormalized(float Velocity)
	{
		AKComp.SetRTPCValue(HazeAudio::RTPC::CircusStickControllerRotationSpeed, Velocity, 0);
	}
}