package com.artificelab.garageitron;
import java.io.IOException;
import android.os.Bundle;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.app.Activity;
import android.content.Intent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;
import android.os.AsyncTask;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.client.*;
import org.apache.http.client.methods.*;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;
import javax.crypto.SecretKey;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import android.util.Base64;
// Import get unix time

public class MainActivity extends Activity {

	protected class NetworkTask extends AsyncTask<String, Void, HttpResponse> {

		@Override
		protected HttpResponse doInBackground(String... params) {
			HttpClient hc = new DefaultHttpClient();
			HttpPost post = new HttpPost(params[0]);
			try {
				HttpResponse resp = hc.execute(post);
				return resp;
			}
			catch(IOException e) {
				e.printStackTrace();
			}
			return null;
		}

		@Override
		protected void onPostExecute(HttpResponse resp) {
		    Toast t = Toast.makeText(getApplicationContext(), resp.getStatusLine().getReasonPhrase(), Toast.LENGTH_SHORT);
		    t.show();
		}
		
	}
	
	Button doorButton;
	Button lightButton;
	
	private StringBuilder getBaseQuery() {
		StringBuilder b = new StringBuilder();
		SharedPreferences sharedPrefs = PreferenceManager.getDefaultSharedPreferences(this);
				
		b.append(sharedPrefs.getString("api_url", "NULL"));
		b.append("?p=");
		
		try {
			Mac mac = Mac.getInstance("HmacSHA1");
			SecretKeySpec secret = new SecretKeySpec(sharedPrefs.getString("auth_key", "NULL").getBytes(), mac.getAlgorithm());
			mac.init(secret);
			int t = (int)(System.currentTimeMillis()/30000L);
			byte[] digest = mac.doFinal(Integer.toString(t).getBytes());
			b.append(Base64.encodeToString(digest, Base64.NO_WRAP));
		} catch (Exception e) {
			e.printStackTrace();
			return new StringBuilder("ERROR");
		}
				
		return b;
	}
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
	
		
		
		doorButton  = (Button) findViewById(R.id.doorButton);
		lightButton = (Button) findViewById(R.id.lightButton);
		
		doorButton.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				Toast t = Toast.makeText(getApplicationContext(), "Pinging door", Toast.LENGTH_LONG);
				t.show();
				StringBuilder b = getBaseQuery();
				b.append("&c=1");
				new NetworkTask().execute(b.toString());
			}
		});
		
		lightButton.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				Toast t = Toast.makeText(getApplicationContext(), "Pinging light", Toast.LENGTH_LONG);
				t.show();
				StringBuilder b= getBaseQuery();
				b.append("&c=2");
				new NetworkTask().execute(b.toString());
			}
		});
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}
	
	@Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
 
        case R.id.action_settings:
            startActivity(new Intent(this, SettingsActivity.class));
            break;
 
        }
 
        return true;
    }
	
}
